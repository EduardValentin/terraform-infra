mock_provider "github" {}

mock_provider "tailscale" {}

run "opencl_native_ssh_is_owner_only" {
  command = plan

  assert {
    condition = length([
      for rule in jsondecode(output.tailscale_policy_json).ssh : rule
      if contains(rule.dst, "tag:solus-agent")
    ]) == 1
    error_message = "Exactly one native SSH rule must target the OpenCL agent."
  }

  assert {
    condition = toset(one([
      for rule in jsondecode(output.tailscale_policy_json).ssh : rule
      if contains(rule.dst, "tag:solus-agent")
      ]).src) == toset([
      "eduard.valentin1996@gmail.com",
      "autogroup:owner"
    ])
    error_message = "Native SSH to the OpenCL agent must be restricted to Eduard and tailnet owners."
  }

  assert {
    condition = one([
      for rule in jsondecode(output.tailscale_policy_json).ssh : rule
      if contains(rule.dst, "tag:solus-agent")
    ]).users == ["root"]
    error_message = "Native SSH to the OpenCL agent must permit only the root Unix account."
  }

  assert {
    condition = anytrue([
      for test in jsondecode(output.tailscale_policy_json).sshTests :
      test.src == "eduard.valentin1996@gmail.com" &&
      test.dst == ["tag:solus-agent"] &&
      try(test.accept, []) == ["root"]
    ])
    error_message = "SSH policy tests must prove root access for Eduard."
  }

  assert {
    condition = anytrue([
      for test in jsondecode(output.tailscale_policy_json).sshTests :
      test.src == "eli.lungu04@gmail.com" &&
      test.dst == ["tag:solus-agent"] &&
      toset(try(test.deny, [])) == toset(["root", "autogroup:nonroot"])
    ])
    error_message = "SSH policy tests must deny root and non-root access for the known regular member."
  }
}
