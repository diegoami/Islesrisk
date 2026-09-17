extends GdUnitTestSuite
## The determinism guarantee the whole engine rests on (ARCHITECTURE.md).


func test_same_seed_gives_the_same_sequence() -> void:
	var a := DeterministicRng.new(20260917)
	var b := DeterministicRng.new(20260917)
	var draws_a: Array[int] = []
	var draws_b: Array[int] = []
	for i: int in 50:
		draws_a.append(a.next_int(0, 1000))
		draws_b.append(b.next_int(0, 1000))
	assert_array(draws_a).is_equal(draws_b)


func test_different_seeds_diverge() -> void:
	var a := DeterministicRng.new(1)
	var b := DeterministicRng.new(2)
	var draws_a: Array[int] = []
	var draws_b: Array[int] = []
	for i: int in 50:
		draws_a.append(a.next_int(0, 1000))
		draws_b.append(b.next_int(0, 1000))
	assert_array(draws_a).is_not_equal(draws_b)


func test_snapshot_resumes_mid_sequence() -> void:
	var original := DeterministicRng.new(4242)
	for i: int in 10:
		original.next_int(0, 100)

	var resumed := DeterministicRng.from_snapshot(original.snapshot())

	var from_original: Array[int] = []
	var from_resumed: Array[int] = []
	for i: int in 20:
		from_original.append(original.next_int(0, 100))
		from_resumed.append(resumed.next_int(0, 100))
	assert_array(from_resumed).is_equal(from_original)


func test_rolls_stay_in_bounds() -> void:
	var rng := DeterministicRng.new(7)
	for i: int in 500:
		var roll: int = rng.roll_die(6)
		assert_int(roll).is_between(1, 6)


func test_shuffle_is_a_permutation_and_leaves_the_input_alone() -> void:
	var source: Array = [1, 2, 3, 4, 5, 6, 7, 8]
	var rng := DeterministicRng.new(99)
	var shuffled: Array = rng.shuffled(source)

	assert_array(source).is_equal([1, 2, 3, 4, 5, 6, 7, 8])
	assert_int(shuffled.size()).is_equal(source.size())
	for value: int in source:
		assert_array(shuffled).contains([value])


func test_shuffle_is_deterministic_for_a_seed() -> void:
	var source: Array = [1, 2, 3, 4, 5, 6, 7, 8]
	var first: Array = DeterministicRng.new(1234).shuffled(source)
	var second: Array = DeterministicRng.new(1234).shuffled(source)
	assert_array(first).is_equal(second)
