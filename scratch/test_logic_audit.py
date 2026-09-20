import sys
from pathlib import Path
sys.path.insert(0, str(Path(__file__).resolve().parent.parent / "bridge"))
from ai_playtest_runner import run_logic_audit

audit = run_logic_audit()
print("Logic audit in edit mode:")
for k, v in audit.items():
    print(f"  {k}: {v}")
