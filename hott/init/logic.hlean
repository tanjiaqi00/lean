/-
Copyright (c) 2014 Microsoft Corporation. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.

Authors: Leonardo de Moura
-/
prelude
import init.datatypes init.reserved_notation

definition not.{l} (a : Type.{l}) := a → empty.{l}
prefix `¬` := not

definition absurd {a : Type} {b : Type} (H₁ : a) (H₂ : ¬a) : b :=
empty.rec (λ e, b) (H₂ H₁)

definition mt {a b : Type} (H₁ : a → b) (H₂ : ¬b) : ¬a :=
assume Ha : a, absurd (H₁ Ha) H₂

-- not
-- ---

protected definition not_empty : ¬ empty :=
assume H : empty, H

definition not_not_intro {a : Type} (Ha : a) : ¬¬a :=
assume Hna : ¬a, absurd Ha Hna

definition not.intro {a : Type} (H : a → empty) : ¬a := H

definition not.elim {a : Type} (H₁ : ¬a) (H₂ : a) : empty := H₁ H₂

definition not_not_of_not_implies {a b : Type} (H : ¬(a → b)) : ¬¬a :=
assume Hna : ¬a, absurd (assume Ha : a, absurd Ha Hna) H

definition not_of_not_implies {a b : Type} (H : ¬(a → b)) : ¬b :=
assume Hb : b, absurd (assume Ha : a, Hb) H

-- eq
-- --

notation a = b := eq a b
definition rfl {A : Type} {a : A} := eq.refl a

namespace eq
  variables {A : Type}
  variables {a b c a' : A}

  definition subst {P : A → Type} (H₁ : a = b) (H₂ : P a) : P b :=
  rec H₂ H₁

  definition trans (H₁ : a = b) (H₂ : b = c) : a = c :=
  subst H₂ H₁

  definition symm (H : a = b) : b = a :=
  subst H (refl a)

  namespace ops
    notation H `⁻¹` := symm H --input with \sy or \-1 or \inv
    notation H1 ⬝ H2 := trans H1 H2
    notation H1 ▸ H2 := subst H1 H2
  end ops
end eq

calc_subst eq.subst
calc_refl  eq.refl
calc_trans eq.trans
calc_symm  eq.symm

namespace lift
  definition down_up.{l₁ l₂} {A : Type.{l₁}} (a : A) : down (up.{l₁ l₂} a) = a :=
  rfl

  definition up_down.{l₁ l₂} {A : Type.{l₁}} (a : lift.{l₁ l₂} A) : up (down a) = a :=
  lift.rec_on a (λ d, rfl)
end lift

-- ne
-- --

definition ne {A : Type} (a b : A) := ¬(a = b)
notation a ≠ b := ne a b

namespace ne
  open eq.ops
  variable {A : Type}
  variables {a b : A}

  definition intro : (a = b → empty) → a ≠ b :=
  assume H, H

  definition elim : a ≠ b → a = b → empty :=
  assume H₁ H₂, H₁ H₂

  definition irrefl : a ≠ a → empty :=
  assume H, H rfl

  definition symm : a ≠ b → b ≠ a :=
  assume (H : a ≠ b) (H₁ : b = a), H (H₁⁻¹)
end ne

section
  open eq.ops
  variables {A : Type} {a b c : A}

  definition false.of_ne : a ≠ a → empty :=
  assume H, H rfl

  definition ne.of_eq_of_ne : a = b → b ≠ c → a ≠ c :=
  assume H₁ H₂, H₁⁻¹ ▸ H₂

  definition ne.of_ne_of_eq : a ≠ b → b = c → a ≠ c :=
  assume H₁ H₂, H₂ ▸ H₁
end

calc_trans ne.of_eq_of_ne
calc_trans ne.of_ne_of_eq

-- iff
-- ---

definition iff (a b : Type) := prod (a → b) (b → a)

notation a <-> b := iff a b
notation a ↔ b := iff a b

namespace iff
  variables {a b c : Type}

  definition def : (a ↔ b) = (prod (a → b) (b → a)) :=
  rfl

  definition intro (H₁ : a → b) (H₂ : b → a) : a ↔ b :=
  prod.mk H₁ H₂

  definition elim (H₁ : (a → b) → (b → a) → c) (H₂ : a ↔ b) : c :=
  prod.rec H₁ H₂

  definition elim_left (H : a ↔ b) : a → b :=
  elim (assume H₁ H₂, H₁) H

  definition mp := @elim_left

  definition elim_right (H : a ↔ b) : b → a :=
  elim (assume H₁ H₂, H₂) H

  definition flip_sign (H₁ : a ↔ b) : ¬a ↔ ¬b :=
  intro
    (assume Hna, mt (elim_right H₁) Hna)
    (assume Hnb, mt (elim_left H₁) Hnb)

  definition refl (a : Type) : a ↔ a :=
  intro (assume H, H) (assume H, H)

  definition rfl {a : Type} : a ↔ a :=
  refl a

  definition trans (H₁ : a ↔ b) (H₂ : b ↔ c) : a ↔ c :=
  intro
    (assume Ha, elim_left H₂ (elim_left H₁ Ha))
    (assume Hc, elim_right H₁ (elim_right H₂ Hc))

  definition symm (H : a ↔ b) : b ↔ a :=
  intro
    (assume Hb, elim_right H Hb)
    (assume Ha, elim_left H Ha)

  definition true_elim (H : a ↔ unit) : a :=
  mp (symm H) unit.star

  definition false_elim (H : a ↔ empty) : ¬a :=
  assume Ha : a, mp H Ha

  open eq.ops
  definition of_eq {a b : Type} (H : a = b) : a ↔ b :=
  iff.intro (λ Ha, H ▸ Ha) (λ Hb, H⁻¹ ▸ Hb)
end iff

calc_refl iff.refl
calc_trans iff.trans

-- inhabited
-- ---------

inductive inhabited [class] (A : Type) : Type :=
mk : A → inhabited A

namespace inhabited

protected definition destruct {A : Type} {B : Type} (H1 : inhabited A) (H2 : A → B) : B :=
inhabited.rec H2 H1

definition fun_inhabited [instance] (A : Type) {B : Type} (H : inhabited B) : inhabited (A → B) :=
destruct H (λb, mk (λa, b))

definition dfun_inhabited [instance] (A : Type) {B : A → Type} (H : Πx, inhabited (B x)) :
  inhabited (Πx, B x) :=
mk (λa, destruct (H a) (λb, b))

definition default (A : Type) [H : inhabited A] : A := destruct H (take a, a)

end inhabited

-- decidable
-- ---------

inductive decidable.{l} [class] (p : Type.{l}) : Type.{l} :=
inl :  p → decidable p,
inr : ¬p → decidable p

namespace decidable
  variables {p q : Type}

  definition pos_witness [C : decidable p] (H : p) : p :=
  rec_on C (λ Hp, Hp) (λ Hnp, absurd H Hnp)

  definition neg_witness [C : decidable p] (H : ¬ p) : ¬ p :=
  rec_on C (λ Hp, absurd Hp H) (λ Hnp, Hnp)

  definition by_cases {q : Type} [C : decidable p] (Hpq : p → q) (Hnpq : ¬p → q) : q :=
  rec_on C (assume Hp, Hpq Hp) (assume Hnp, Hnpq Hnp)

  definition em (p : Type) [H : decidable p] : sum p ¬p :=
  by_cases (λ Hp, sum.inl Hp) (λ Hnp, sum.inr Hnp)

  definition by_contradiction [Hp : decidable p] (H : ¬p → empty) : p :=
  by_cases
    (assume H₁ : p, H₁)
    (assume H₁ : ¬p, empty.rec (λ e, p) (H H₁))

  definition decidable_iff_equiv (Hp : decidable p) (H : p ↔ q) : decidable q :=
  rec_on Hp
    (assume Hp : p,   inl (iff.elim_left H Hp))
    (assume Hnp : ¬p, inr (iff.elim_left (iff.flip_sign H) Hnp))

  definition decidable_eq_equiv.{l} {p q : Type.{l}} (Hp : decidable p) (H : p = q) : decidable q :=
  decidable_iff_equiv Hp (iff.of_eq H)
end decidable

section
  variables {p q : Type}
  open decidable (rec_on inl inr)

  definition unit.decidable [instance] : decidable unit :=
  inl unit.star

  definition empty.decidable [instance] : decidable empty :=
  inr not_empty

  definition prod.decidable [instance] (Hp : decidable p) (Hq : decidable q) : decidable (prod p q) :=
  rec_on Hp
    (assume Hp  : p, rec_on Hq
      (assume Hq  : q,  inl (prod.mk Hp Hq))
      (assume Hnq : ¬q, inr (λ H : prod p q, prod.rec_on H (λ Hp Hq, absurd Hq Hnq))))
    (assume Hnp : ¬p, inr (λ H : prod p q, prod.rec_on H (λ Hp Hq, absurd Hp Hnp)))

  definition sum.decidable [instance] (Hp : decidable p) (Hq : decidable q) : decidable (sum p q) :=
  rec_on Hp
    (assume Hp  : p, inl (sum.inl Hp))
    (assume Hnp : ¬p, rec_on Hq
      (assume Hq  : q,  inl (sum.inr Hq))
      (assume Hnq : ¬q, inr (λ H : sum p q, sum.rec_on H (λ Hp, absurd Hp Hnp) (λ Hq, absurd Hq Hnq))))

  definition not.decidable [instance] (Hp : decidable p) : decidable (¬p) :=
  rec_on Hp
    (assume Hp,  inr (not_not_intro Hp))
    (assume Hnp, inl Hnp)

  definition implies.decidable [instance] (Hp : decidable p) (Hq : decidable q) : decidable (p → q) :=
  rec_on Hp
    (assume Hp  : p, rec_on Hq
      (assume Hq  : q,  inl (assume H, Hq))
      (assume Hnq : ¬q, inr (assume H : p → q, absurd (H Hp) Hnq)))
    (assume Hnp : ¬p, inl (assume Hp, absurd Hp Hnp))

  definition iff.decidable [instance] (Hp : decidable p) (Hq : decidable q) : decidable (p ↔ q) := _
end

definition decidable_pred {A : Type} (R : A   →   Type) := Π (a   : A), decidable (R a)
definition decidable_rel  {A : Type} (R : A → A → Type) := Π (a b : A), decidable (R a b)
definition decidable_eq   (A : Type) := decidable_rel (@eq A)

definition ite (c : Type) [H : decidable c] {A : Type} (t e : A) : A :=
decidable.rec_on H (λ Hc, t) (λ Hnc, e)

definition if_pos {c : Type} [H : decidable c] (Hc : c) {A : Type} {t e : A} : (if c then t else e) = t :=
decidable.rec
  (λ Hc : c,    eq.refl (@ite c (decidable.inl Hc) A t e))
  (λ Hnc : ¬c,  absurd Hc Hnc)
  H

definition if_neg {c : Type} [H : decidable c] (Hnc : ¬c) {A : Type} {t e : A} : (if c then t else e) = e :=
decidable.rec
  (λ Hc : c,    absurd Hc Hnc)
  (λ Hnc : ¬c,  eq.refl (@ite c (decidable.inr Hnc) A t e))
  H

definition if_t_t (c : Type) [H : decidable c] {A : Type} (t : A) : (if c then t else t) = t :=
decidable.rec
  (λ Hc  : c,  eq.refl (@ite c (decidable.inl Hc)  A t t))
  (λ Hnc : ¬c, eq.refl (@ite c (decidable.inr Hnc) A t t))
  H

definition if_unit {A : Type} (t e : A) : (if unit then t else e) = t :=
if_pos unit.star

definition if_empty {A : Type} (t e : A) : (if empty then t else e) = e :=
if_neg not_empty

definition if_cond_congr {c₁ c₂ : Type} [H₁ : decidable c₁] [H₂ : decidable c₂] (Heq : c₁ ↔ c₂) {A : Type} (t e : A)
                      : (if c₁ then t else e) = (if c₂ then t else e) :=
decidable.rec_on H₁
 (λ Hc₁  : c₁,  decidable.rec_on H₂
   (λ Hc₂  : c₂,  if_pos Hc₁ ⬝ (if_pos Hc₂)⁻¹)
   (λ Hnc₂ : ¬c₂, absurd (iff.elim_left Heq Hc₁) Hnc₂))
 (λ Hnc₁ : ¬c₁, decidable.rec_on H₂
   (λ Hc₂  : c₂,  absurd (iff.elim_right Heq Hc₂) Hnc₁)
   (λ Hnc₂ : ¬c₂, if_neg Hnc₁ ⬝ (if_neg Hnc₂)⁻¹))

definition if_congr_aux {c₁ c₂ : Type} [H₁ : decidable c₁] [H₂ : decidable c₂] {A : Type} {t₁ t₂ e₁ e₂ : A}
                     (Hc : c₁ ↔ c₂) (Ht : t₁ = t₂) (He : e₁ = e₂) :
                 (if c₁ then t₁ else e₁) = (if c₂ then t₂ else e₂) :=
Ht ▸ He ▸ (if_cond_congr Hc t₁ e₁)

definition if_congr {c₁ c₂ : Type} [H₁ : decidable c₁] {A : Type} {t₁ t₂ e₁ e₂ : A} (Hc : c₁ ↔ c₂) (Ht : t₁ = t₂) (He : e₁ = e₂) :
                 (if c₁ then t₁ else e₁) = (@ite c₂ (decidable.decidable_iff_equiv H₁ Hc) A t₂ e₂) :=
have H2 [visible] : decidable c₂, from (decidable.decidable_iff_equiv H₁ Hc),
if_congr_aux Hc Ht He


-- We use "dependent" if-then-else to be able to communicate the if-then-else condition
-- to the branches
definition dite (c : Type) [H : decidable c] {A : Type} (t : c → A) (e : ¬ c → A) : A :=
decidable.rec_on H (λ Hc, t Hc) (λ Hnc, e Hnc)

definition dif_pos {c : Type} [H : decidable c] (Hc : c) {A : Type} {t : c → A} {e : ¬ c → A} : (if H : c then t H else e H) = t (decidable.pos_witness Hc) :=
decidable.rec
  (λ Hc : c,    eq.refl (@dite c (decidable.inl Hc) A t e))
  (λ Hnc : ¬c,  absurd Hc Hnc)
  H

definition dif_neg {c : Type} [H : decidable c] (Hnc : ¬c) {A : Type} {t : c → A} {e : ¬ c → A} : (if H : c then t H else e H) = e (decidable.neg_witness Hnc) :=
decidable.rec
  (λ Hc : c,    absurd Hc Hnc)
  (λ Hnc : ¬c,  eq.refl (@dite c (decidable.inr Hnc) A t e))
  H

-- Remark: dite and ite are "definitionally equal" when we ignore the proofs.
definition dite_ite_eq (c : Type) [H : decidable c] {A : Type} (t : A) (e : A) : dite c (λh, t) (λh, e) = ite c t e :=
rfl
