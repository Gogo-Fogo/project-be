# Grid security: what a household can actually do

The grid itself is defended by utilities and national agencies (in the US: CISA and the FBI).
A household's part is:
- keep its own devices from being used in attacks
- ease the load when the grid is stressed
- be ready when it fails
- report what it sees
- and, optionally, learn the skills legally

**Never** scan, probe or "test" equipment or networks that aren't yours, even to help. It's a
crime and can cause the very outage you're worried about.

## 1. Don't be part of a botnet (home network)
Attacks on infrastructure are often launched from millions of hacked home routers and gadgets.
- [ ] Update the router's software and turn on auto-update.
- [ ] Change the router's admin password from the default. Turn off **WPS**, **UPnP**, and
      remote admin if you don't use it.
- [ ] Wi-Fi on **WPA3** (or WPA2-AES) with a long password.
- [ ] List every device on the network. Update or remove old cameras, smart plugs, TVs and baby
      monitors, and change their default passwords.
- [ ] Put smart-home gadgets on the **guest network**, away from computers and phones.
- [ ] A router more than about 5 years old with no updates: replace it.
- [ ] OS updates and the built-in antivirus left on.

## 2. Lock down accounts
- [ ] Two-factor login (an authenticator app or passkeys) on email, phone accounts, bank and the
      **utility account**.
- [ ] A password manager. No reused passwords.
- [ ] Watch for phishing that pretends to be the power company ("pay now or we cut you off").
      Call the number on your bill instead.

## 3. Ease the grid's load
Grids fail most often at peak demand.
- [ ] Join the utility's **demand-response / peak-saver** program (it often pays you).
- [ ] During grid alerts, cut big loads: heat or AC a few degrees, no laundry, dishwasher or
      gaming at peak (usually 4–9 pm).
- [ ] Charge the power station from solar or off-peak.

## 4. Be ready when it fails
- [ ] This kit installed and tested offline.
- [ ] [READY-2-WEEKS.md](READY-2-WEEKS.md) and [COMMS-PLAN.md](COMMS-PLAN.md) done.
- [ ] First-aid / CPR class for the family.

## 5. Report, don't investigate
- [ ] Suspicious activity at substations or power lines → the emergency number (if urgent) or
      the utility.
- [ ] Cyber incidents (US) → **report@cisa.gov** or **ic3.gov** (FBI). Elsewhere, your national
      cyber agency.
- [ ] Phishing that pretends to be the utility → forward it to the utility and to
      **reportphishing@apwg.org**.

## 6. Community
- [ ] Join the local **CERT** (Community Emergency Response Team, US), or your country's
      volunteer equivalent. The training is free.
- [ ] Know which neighbours depend on power for medical devices, and check on them in outages.

## 7. Learn it legally (optional)
- [ ] **CISA ICS training:** free online introduction to industrial control system security.
- [ ] **GRFICSv2** (github.com/Fortiphyd/GRFICSv2): a simulated plant in virtual machines, to
      attack and defend safely.
- [ ] CISA **Malcolm** and **ICSNPP** (GitHub `cisagov`): how defenders watch industrial
      networks. Run them only on your own lab.
- [ ] Entry certifications if it becomes a career: **GICSP**, ISA/IEC 62443.
