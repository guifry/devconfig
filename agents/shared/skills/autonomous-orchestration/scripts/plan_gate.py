import sys,re
req=["Rule ownership","Delete list","Failure modes","Performance","Risky core and invariant tests","Worked examples","Acceptance checklist"]
s=open(sys.argv[1]).read()
heads=[h.strip().lower() for h in re.findall(r"^#{2,3}\s+(?:[0-9][0-9A-Za-z.]*\s+)?(.+)$",s,re.M)]
miss=[r for r in req if not any(h.startswith(r.lower()) for h in heads)]
print("GATE: PASS" if not miss else "GATE: MISSING "+", ".join(miss)); sys.exit(1 if miss else 0)
