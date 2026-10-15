class_name FighterRoster
extends RefCounted

const DATA_PATHS: Array[String] = [
	"res://resources/fighter_data/ngoc_vy.tres",
	"res://resources/fighter_data/mai_anh.tres",
	"res://resources/fighter_data/huyen_chi.tres",
	"res://resources/fighter_data/hong_nhi.tres",
	"res://resources/fighter_data/bao_chau.tres",
	"res://resources/fighter_data/tu_anh.tres",
	"res://resources/fighter_data/thanh_van.tres",
	"res://resources/fighter_data/anh_duong.tres",
]

static func get_fighter(id: int) -> FighterData:
	return load(DATA_PATHS[clampi(id, 0, DATA_PATHS.size() - 1)]) as FighterData

static func all() -> Array[FighterData]:
	var result: Array[FighterData] = []
	for path in DATA_PATHS:
		result.append(load(path) as FighterData)
	return result
