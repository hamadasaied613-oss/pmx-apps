# PMX Domain Status

**Current URL**: https://hamadasaied613-oss.github.io/pmx-apps/
**Custom Domain**: pmxs.space (DNS propagating)

## When DNS Resolves
1. `gh api repos/hamadasaied613-oss/pmx-apps/pages -X PUT -H "Accept: application/vnd.github.v3+json" -f cname=pmxs.space`
2. HTTPS auto-provisions via Let's Encrypt

## DNS Ready
- 4 A records -> GitHub Pages IPs
- CNAME www -> hamadasaied613-oss.github.io
- MX records -> Zoho Mail (ready for email setup)
- SPF TXT -> Zoho email authentication
