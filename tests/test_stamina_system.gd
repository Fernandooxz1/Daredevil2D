extends SceneTree

func _init():
	_run_suite.call_deferred()

func _run_suite() -> void:
	print("\n==================================================")
	print("  TEST SUITE: REDISEÑO DEL SISTEMA DE ESTAMINA")
	print("==================================================\n")
	
	var stats = {"passed": 0, "total": 0}
	
	# Helper assertions
	var assert_test = func(condition: bool, test_name: String):
		stats["total"] += 1
		if condition:
			stats["passed"] += 1
			print("[PASS] %s" % test_name)
		else:
			push_error("[FAIL] %s" % test_name)
			print("[FAIL] %s" % test_name)

	# Instanciar Daredevil
	var dd_scene = load("res://scenes/daredevil.tscn")
	var dd = dd_scene.instantiate()
	root.add_child(dd)
	
	# Esperar un frame de procesamiento para que el ciclo de vida esté 100% activo
	await process_frame

	# ----------------------------------------------------
	# TEST 1: Recovery Delay (0.8s en Modo Exploración)
	# ----------------------------------------------------
	print("--- TEST 1: Recovery Delay (0.8s) ---")
	dd.is_combat_stance = false
	dd.energy = 100.0
	dd.stamina_recovery_timer = 0.0
	dd.drain_energy(20.0)
	
	assert_test.call(is_equal_approx(dd.energy, 80.0), "1.1: Energía tras drain es 80.0")
	assert_test.call(is_equal_approx(dd.stamina_recovery_timer, 0.8), "1.2: Timer de recuperación iniciado en 0.8s")
	
	# Avanzar 0.4s de física: no debe haber recuperación
	dd._physics_process(0.4)
	assert_test.call(is_equal_approx(dd.energy, 80.0), "1.3: Energía sigue en 80.0 tras 0.4s (bloqueada por delay)")
	assert_test.call(is_equal_approx(dd.stamina_recovery_timer, 0.4), "1.4: Timer de recuperación decrementó a 0.4s")
	
	# Avanzar otros 0.4s: el timer llega a 0
	dd._physics_process(0.4)
	assert_test.call(is_equal_approx(dd.stamina_recovery_timer, 0.0), "1.5: Timer de recuperación se agotó a 0.0s")

	# ----------------------------------------------------
	# TEST 2: Recarga continua por segundo (Delta)
	# ----------------------------------------------------
	print("\n--- TEST 2: Recarga Continua por Segundo ---")
	# Tasa exploración: 32.0 pts/s. En 0.5s debe recuperar 16.0 pts
	var initial_energy = dd.energy # 80.0
	dd._physics_process(0.5)
	var expected_energy = initial_energy + (32.0 * 0.5)
	assert_test.call(is_equal_approx(dd.energy, expected_energy), "2.1: En 0.5s recupera 16.0 pts (pasa a 96.0)")
	
	# En 0.5s más debe llegar al tope MAX_ENERGY (100.0) sin sobrepasarlo
	dd._physics_process(0.5)
	assert_test.call(is_equal_approx(dd.energy, 100.0), "2.2: Se satura exactamente en MAX_ENERGY (100.0)")

	# ----------------------------------------------------
	# TEST 3: Estado de Fatiga (Exhaustion) y Umbral del 30%
	# ----------------------------------------------------
	print("\n--- TEST 3: Fatiga y Umbral de Salida (30%) ---")
	dd.drain_energy(100.0)
	assert_test.call(is_equal_approx(dd.energy, 0.0), "3.1: Energía llega a 0.0")
	assert_test.call(dd.is_exhausted == true, "3.2: is_exhausted es true al vaciarse")
	
	# Reembolsar a 20 pts (debajo del umbral de 30)
	dd.refund_energy(20.0)
	assert_test.call(is_equal_approx(dd.energy, 20.0), "3.3: Energía es 20.0")
	assert_test.call(dd.is_exhausted == true, "3.4: Sigue en fatiga con 20% (< 30%)")
	
	# Reembolsar 15 pts más (llega a 35, supera el umbral)
	dd.refund_energy(15.0)
	assert_test.call(is_equal_approx(dd.energy, 35.0), "3.5: Energía es 35.0")
	assert_test.call(dd.is_exhausted == false, "3.6: Sale de fatiga al superar 30%")

	# ----------------------------------------------------
	# Instanciar Ladrón como atacante
	# ----------------------------------------------------
	var ladron_scene = load("res://scenes/ladron.tscn")
	var fake_attacker = ladron_scene.instantiate()
	root.add_child(fake_attacker)
	await process_frame
	
	var hit_data = {"attacker": fake_attacker}

	# ----------------------------------------------------
	# TEST 4: Parry Perfecto
	# ----------------------------------------------------
	print("\n--- TEST 4: Parry Perfecto ---")
	Input.action_press("blokear")
	await process_frame
	
	dd.parry_window_timer = 0.15
	dd.energy = 50.0
	var health_before_parry = dd.health_comp.current_health
	
	dd.health_comp.take_damage(20, hit_data)
	
	assert_test.call(dd.health_comp.current_health == health_before_parry, "4.1: Salud intacta (0 daño mitigado 100%)")
	assert_test.call(is_equal_approx(dd.energy, 75.0), "4.2: Estamina aumenta +25 por parry perfecto (de 50 a 75)")
	assert_test.call(fake_attacker.is_stunned == true, "4.3: Atacante contra-staggered (is_stunned = true)")

	# ----------------------------------------------------
	# TEST 5: Bloqueo Regular
	# ----------------------------------------------------
	print("\n--- TEST 5: Bloqueo Regular ---")
	dd.parry_window_timer = 0.0 # Ventana de parry cerrada
	dd.energy = 50.0
	var health_before_block = dd.health_comp.current_health
	
	# Daño entrante = 20 -> Coste estamina = max(20 * 0.8, 12.0) = 16.0
	dd.health_comp.take_damage(20, hit_data)
	
	assert_test.call(dd.health_comp.current_health == health_before_block, "5.1: Salud intacta tras bloqueo regular")
	assert_test.call(is_equal_approx(dd.energy, 34.0), "5.2: Estamina drena exactamente 16.0 pts (de 50 a 34)")

	# ----------------------------------------------------
	# TEST 6: Guard Break y Sangrado
	# ----------------------------------------------------
	print("\n--- TEST 6: Guard Break ---")
	dd.parry_window_timer = 0.0
	dd.energy = 8.0 # Menor que 16.0 requeridos
	var health_before_gb = dd.health_comp.current_health
	
	dd.health_comp.take_damage(20, hit_data)
	
	assert_test.call(dd.is_guard_broken == true, "6.1: is_guard_broken activado")
	assert_test.call(is_equal_approx(dd.guard_break_timer, 0.8), "6.2: guard_break_timer iniciado en 0.8s")
	assert_test.call(dd.is_exhausted == true, "6.3: entra en fatiga directamente")
	assert_test.call(is_equal_approx(dd.energy, 0.0), "6.4: estamina queda en 0.0")
	# Sangrado del 25% de 20 = 5 de daño
	assert_test.call(dd.health_comp.current_health == health_before_gb - 5, "6.5: Sangrado de 25% aplicado a la salud (5 pts de daño)")

	# ----------------------------------------------------
	# TEST 7: Uppercut Refund (+15 estamina)
	# ----------------------------------------------------
	print("\n--- TEST 7: Momentum Refund en Uppercut ---")
	dd.energy = 40.0
	var dummy_health_comp = HealthComponent.new()
	root.add_child(dummy_health_comp)
	await process_frame
	
	dd.hitbox_component.on_hit_landed.emit(dummy_health_comp, {"attack_type": "hit4", "combo_step": 4})
	assert_test.call(is_equal_approx(dd.energy, 55.0), "7.1: Uppercut reembolsa +15.0 pts de estamina (de 40 a 55)")

	Input.action_release("blokear")
	await process_frame
	
	fake_attacker.queue_free()
	dummy_health_comp.queue_free()
	dd.queue_free()

	print("\n==================================================")
	print("  RESULTADOS: %d / %d TESTS PASADOS" % [stats["passed"], stats["total"]])
	print("==================================================\n")
	
	if stats["passed"] == stats["total"]:
		print("¡TODAS LAS PRUEBAS COMPLETADAS CON ÉXITO!\n")
		quit(0)
	else:
		push_error("AL MENOS UN TEST FALLÓ")
		quit(1)
