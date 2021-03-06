/-
Copyright (c) 2014 Floris van Doorn. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.
Author: Floris van Doorn

Theorems about W-types (well-founded trees)
-/

import .sigma .pi
open eq sigma sigma.ops equiv is_equiv

-- TODO fix universe levels
exit

inductive Wtype.{l k} {A : Type.{l}} (B : A → Type.{k}) :=
sup : Π (a : A), (B a → Wtype.{l k} B) → Wtype.{l k} B

namespace Wtype
  notation `W` binders `,` r:(scoped B, Wtype B) := r

  universe variables u v
  variables {A A' : Type.{u}} {B B' : A → Type.{v}} {C : Π(a : A), B a → Type}
            {a a' : A} {f : B a → W a, B a} {f' : B a' → W a, B a} {w w' : W(a : A), B a}

  definition pr1 (w : W(a : A), B a) : A :=
  Wtype.rec_on w (λa f IH, a)

  definition pr2 (w : W(a : A), B a) : B (pr1 w) → W(a : A), B a :=
  Wtype.rec_on w (λa f IH, f)

  namespace ops
  postfix `.1`:(max+1) := Wtype.pr1
  postfix `.2`:(max+1) := Wtype.pr2
  notation `⟨` a `,` f `⟩`:0 := Wtype.sup a f --input ⟨ ⟩ as \< \>
  end ops
  open ops

  protected definition eta (w : W a, B a) : ⟨w.1 , w.2⟩ = w :=
  cases_on w (λa f, idp)

  definition path_W_sup (p : a = a') (q : p ▹ f = f') : ⟨a, f⟩ = ⟨a', f'⟩ :=
  path.rec_on p (λf' q, path.rec_on q idp) f' q

  definition path_W (p : w.1 = w'.1) (q : p ▹ w.2 = w'.2) : w = w' :=
  cases_on w
           (λw1 w2, cases_on w' (λ w1' w2', path_W_sup))
           p q

  definition pr1_path (p : w = w') : w.1 = w'.1 :=
  path.rec_on p idp

  definition pr2_path (p : w = w') : pr1_path p ▹ w.2 = w'.2 :=
  path.rec_on p idp

  namespace ops
  postfix `..1`:(max+1) := pr1_path
  postfix `..2`:(max+1) := pr2_path
  end ops
  open ops

  definition sup_path_W (p : w.1 = w'.1) (q : p ▹ w.2 = w'.2)
      :  dpair (path_W p q)..1 (path_W p q)..2 = dpair p q :=
  begin
    reverts (p, q),
    apply (cases_on w), intros (w1, w2),
    apply (cases_on w'), intros (w1', w2', p), generalize w2', --change to revert
    apply (path.rec_on p), intros (w2', q),
    apply (path.rec_on q), apply idp
  end

  definition pr1_path_W (p : w.1 = w'.1) (q : p ▹ w.2 = w'.2) : (path_W p q)..1 = p :=
  (!sup_path_W)..1

  definition pr2_path_W (p : w.1 = w'.1) (q : p ▹ w.2 = w'.2)
      : pr1_path_W p q ▹ (path_W p q)..2 = q :=
  (!sup_path_W)..2

  definition eta_path_W (p : w = w') : path_W (p..1) (p..2) = p :=
  begin
    apply (path.rec_on p),
    apply (cases_on w), intros (w1, w2),
    apply idp
  end

  definition transport_pr1_path_W {B' : A → Type} (p : w.1 = w'.1) (q : p ▹ w.2 = w'.2)
      : transport (λx, B' x.1) (path_W p q) = transport B' p :=
  begin
    reverts (p, q),
    apply (cases_on w), intros (w1, w2),
    apply (cases_on w'), intros (w1', w2', p), generalize w2',
    apply (path.rec_on p), intros (w2', q),
    apply (path.rec_on q), apply idp
  end

  definition path_W_uncurried (pq : Σ(p : w.1 = w'.1), p ▹ w.2 = w'.2) : w = w' :=
  destruct pq path_W

  definition sup_path_W_uncurried (pq : Σ(p : w.1 = w'.1), p ▹ w.2 = w'.2)
      :  dpair (path_W_uncurried pq)..1 (path_W_uncurried pq)..2 = pq :=
  destruct pq sup_path_W

  definition pr1_path_W_uncurried (pq : Σ(p : w.1 = w'.1), p ▹ w.2 = w'.2)
      : (path_W_uncurried pq)..1 = pq.1 :=
  (!sup_path_W_uncurried)..1

  definition pr2_path_W_uncurried (pq : Σ(p : w.1 = w'.1), p ▹ w.2 = w'.2)
      : (pr1_path_W_uncurried pq) ▹ (path_W_uncurried pq)..2 = pq.2 :=
  (!sup_path_W_uncurried)..2

  definition eta_path_W_uncurried (p : w = w') : path_W_uncurried (dpair p..1 p..2) = p :=
  !eta_path_W

  definition transport_pr1_path_W_uncurried {B' : A → Type} (pq : Σ(p : w.1 = w'.1), p ▹ w.2 = w'.2)
      : transport (λx, B' x.1) (@path_W_uncurried A B w w' pq) = transport B' pq.1 :=
    destruct pq transport_pr1_path_W

  definition isequiv_path_W /-[instance]-/ (w w' : W a, B a)
      : is_equiv (@path_W_uncurried A B w w') :=
  adjointify path_W_uncurried
             (λp, dpair (p..1) (p..2))
             eta_path_W_uncurried
             sup_path_W_uncurried

  definition equiv_path_W (w w' : W a, B a) : (Σ(p : w.1 = w'.1),  p ▹ w.2 = w'.2) ≃ (w = w') :=
  equiv.mk path_W_uncurried !isequiv_path_W

  definition double_induction_on {P : (W a, B a) → (W a, B a) → Type} (w w' : W a, B a)
    (H : ∀ (a a' : A) (f : B a → W a, B a) (f' : B a' → W a, B a),
      (∀ (b : B a) (b' : B a'), P (f b) (f' b')) → P (sup a f) (sup a' f')) : P w w' :=
  begin
    revert w',
    apply (rec_on w), intros (a, f, IH, w'),
    apply (cases_on w'), intros (a', f'),
    apply H, intros (b, b'),
    apply IH
  end

  /- truncatedness -/
  open truncation
  definition trunc_W [FUN : funext.{v (max 1 u v)}] (n : trunc_index) [HA : is_trunc (n.+1) A]
    : is_trunc (n.+1) (W a, B a) :=
  begin
  fapply is_trunc_succ, intros (w, w'),
  apply (double_induction_on w w'), intros (a, a', f, f', IH),
  fapply trunc_equiv',
    apply equiv_path_W,
    apply trunc_sigma,
      fapply (succ_is_trunc n),
      intro p, revert IH, generalize f', --change to revert after simpl
      apply (path.rec_on p), intros (f', IH),
      apply pi.trunc_path_pi, intro b,
      apply IH
  end

end Wtype
