assert(name("a", "b"):append_after(1) == name("a", "b_1"))
assert(name("a", 1):append_after(2) == name("a", 1, "_2"))
assert(name("a", "b"):append_after("k") == name("a", "bk"))
assert(name("a", "b"):append_before("k") == name("a", "kb"))
assert(name("a", 1):append_before("k") == name("a", "k", 1))
assert(name():append_after("a") == name("a"))
assert(name():append_after(1) == name("_1"))
assert(name():append_before("b") == name("b"))
