extends SceneTree

const MODEL := preload("res://scripts/universe_graph_model.gd")

var failures := 0


func _init() -> void:
	call_deferred("_run_tests")


func _run_tests() -> void:
	var model = MODEL.new()
	var expectations := {
		0: {"min_nodes": 40, "min_avg_degree": 4.3},
		3: {"min_nodes": 58, "min_avg_degree": 5.2},
		6: {"min_nodes": 82, "min_avg_degree": 5.6},
		7: {"min_nodes": 92, "min_avg_degree": 5.6},
		12: {"min_nodes": 122, "min_avg_degree": 5.8},
		25: {"min_nodes": 144, "min_avg_degree": 5.8},
	}
	for region_index in expectations:
		var expected: Dictionary = expectations[region_index]
		model.new_expedition(1000 + region_index)
		for _advance in region_index:
			model.advance_region()
			if model.state != model.State.REGION_COMPLETE:
				model.state = model.State.REGION_COMPLETE
		var started := Time.get_ticks_msec()
		if region_index > 0:
			model.state = model.State.REGION_COMPLETE
			model.advance_region()
		var elapsed := Time.get_ticks_msec() - started
		var node_count: int = model.positions.size()
		var minimum_degree := 99
		var maximum_degree := 0
		var total_degree := 0
		for node_neighbors in model.neighbors:
			minimum_degree = mini(minimum_degree, node_neighbors.size())
			maximum_degree = maxi(maximum_degree, node_neighbors.size())
			total_degree += node_neighbors.size()
		var average_degree := float(total_degree) / maxf(1.0, float(node_count))
		var label := "region %d" % region_index
		_expect(node_count >= int(expected.min_nodes), "%s has enough cells." % label)
		_expect(
			average_degree >= float(expected.min_avg_degree),
			"%s has traditional average degree (%.2f)." % [label, average_degree]
		)
		_expect(minimum_degree >= 2, "%s has no isolated cell." % label)
		_expect(maximum_degree <= 8, "%s respects the degree cap." % label)
		_validate_connected(model, label)
		_validate_mine_count(model, label)
		_expect(elapsed < 3000, "%s generates quickly (%dms)." % [label, elapsed])
		print(
			"%s: nodes=%d avg=%.2f min=%d max=%d mines=%d %dms" % [
				label,
				node_count,
				average_degree,
				minimum_degree,
				maximum_degree,
				model.mine_count,
				elapsed,
			]
		)
	if failures == 0:
		print("Universe graph density tests passed.")
		quit(0)
	else:
		push_error("%d universe graph density test(s) failed." % failures)
		quit(1)


func _validate_connected(model, label: String) -> void:
	if model.positions.is_empty():
		_expect(false, "%s has nodes." % label)
		return
	var visited := {}
	var pending: Array[int] = [0]
	visited[0] = true
	while not pending.is_empty():
		var node_index: int = pending.pop_back()
		for neighbor in model.neighbors[node_index]:
			if not visited.has(int(neighbor)):
				visited[int(neighbor)] = true
				pending.append(int(neighbor))
	_expect(visited.size() == model.positions.size(), "%s is fully connected." % label)


func _validate_mine_count(model, label: String) -> void:
	var mine_total := 0
	for mine in model.mines:
		mine_total += int(mine)
	_expect(mine_total == model.mine_count, "%s places every mine." % label)
	_expect(mine_total >= 2, "%s has mines." % label)


func _expect(condition: bool, message: String) -> void:
	if condition:
		return
	failures += 1
	push_error(message)
