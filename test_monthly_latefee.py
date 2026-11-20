"""
Test: Monthly Recurring Late Fee Logic
Today: auto-detected
Tests both the helper function in views.py AND the serializer logic.
"""
import os, sys, django
os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'config.settings')
sys.path.insert(0, os.path.join(os.path.dirname(__file__), 'backend'))
django.setup()

from datetime import date
from decimal import Decimal
import datetime

# ----- Import the helper we just wrote -----
from finance.views import _count_overdue_months, calculate_late_fee

TODAY = date.today()
print(f"Today: {TODAY}")
print("=" * 60)

# ---- Helper to build a fake due_date N full months ago ----
def months_ago(n):
    # Exactly n full months before today  (same day last month × n)
    d = TODAY
    for _ in range(n):
        # go back one month
        if d.month == 1:
            d = d.replace(year=d.year - 1, month=12)
        else:
            d = d.replace(month=d.month - 1)
    return d

def months_ago_minus1day(n):
    """n months ago minus 1 day — just under n full months overdue."""
    base = months_ago(n)
    return base + __import__('datetime').timedelta(days=1)

PERCENT = Decimal('5.00')
BASE = Decimal('2800.00')

cases = [
    # (description, due_date, expected_months, expected_late_fee)
    ("Future date (tomorrow)",      TODAY + __import__('datetime').timedelta(days=1),  0,  Decimal('0')),
    ("Due today",                    TODAY,                                              0,  Decimal('0')),
    ("1 day overdue (< 1 month)",   TODAY - __import__('datetime').timedelta(days=1),  0,  Decimal('0')),
    ("Just under 1 full month",     months_ago_minus1day(1),                           0,  Decimal('0')),
    ("Exactly 1 full month ago",    months_ago(1),                                     1,  round(BASE * PERCENT / 100, 2)),
    ("Exactly 2 full months ago",   months_ago(2),                                     2,  round(BASE * PERCENT * 2 / 100, 2)),
    ("Exactly 3 full months ago",   months_ago(3),                                     3,  round(BASE * PERCENT * 3 / 100, 2)),
    ("Exactly 6 full months ago",   months_ago(6),                                     6,  round(BASE * PERCENT * 6 / 100, 2)),
]

all_passed = True
for desc, due_date, exp_months, exp_fee in cases:
    got_months = _count_overdue_months(due_date)
    got_months2, got_fee = calculate_late_fee(BASE, due_date, PERCENT)
    
    ok_months = (got_months == exp_months)
    ok_fee    = (got_fee == exp_fee)
    ok = ok_months and ok_fee
    
    status_str = "✓ PASS" if ok else "✗ FAIL"
    if not ok:
        all_passed = False
    
    print(f"{status_str} | {desc}")
    print(f"         due_date={due_date}  exp_months={exp_months}  got_months={got_months}  exp_fee=₹{exp_fee}  got_fee=₹{got_fee}")
    if not ok:
        if not ok_months:
            print(f"         !! months mismatch: expected {exp_months}, got {got_months}")
        if not ok_fee:
            print(f"         !! fee mismatch: expected {exp_fee}, got {got_fee}")

print("=" * 60)

# ---- Also test serializer _count_overdue_months via a fake obj ----
print("\n--- Serializer helper test ---")
from finance.serializers import MaintenanceBillSerializer

ser = MaintenanceBillSerializer()

for n in [0, 1, 2, 3]:
    due = months_ago(n) if n > 0 else TODAY
    got = ser._count_overdue_months(due)
    exp = n
    ok = (got == exp)
    print(f"{'✓' if ok else '✗'} serializer._count_overdue_months({due}) = {got}  (expected {exp})")
    if not ok:
        all_passed = False

print("=" * 60)
if all_passed:
    print("=== ALL TESTS PASSED PERFECTLY! ===")
else:
    print("=== SOME TESTS FAILED — see above ===")
    sys.exit(1)
