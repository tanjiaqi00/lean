import standard
using tactic

theorem tst {A B : Bool} (H1 : A) (H2 : B) : A
:= by state; exact

check tst