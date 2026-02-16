# Tailscale Tags and ACL Baseline

```json
{
  "tagOwners": {
    "tag:prod": ["group:admin"],
    "tag:test": ["group:admin"],
    "tag:ops": ["group:admin"],
    "tag:ci": ["group:admin"]
  },
  "acls": [
    {
      "action": "accept",
      "src": ["tag:ci"],
      "dst": ["tag:test:*", "tag:prod:*"]
    },
    {
      "action": "accept",
      "src": ["group:admin"],
      "dst": ["tag:prod:*", "tag:test:*", "tag:ops:*"]
    }
  ],
  "ssh": [
    {
      "action": "accept",
      "src": ["group:admin"],
      "dst": ["tag:prod", "tag:test", "tag:ops"],
      "users": ["root", "ubuntu"]
    }
  ]
}
```

Use reusable pre-auth keys restricted to the relevant tag set.
