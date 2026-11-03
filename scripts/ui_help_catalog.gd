extends RefCounted

const ART := preload("res://scripts/art_catalog.gd")

const SECTION_ORDER = [&"land", &"ocean", &"sky", &"universe", &"menus"]

const SECTION_TITLES = {
	&"land": "TXT_0057",
	&"ocean": "TXT_0058",
	&"sky": "TXT_0517",
	&"universe": "TXT_0518",
	&"menus": "TXT_0519",
}

const LABELS = {
	"title": "TXT_0509",
	"index": "TXT_0510",
	"previous": "TXT_0514",
	"next": "TXT_0515",
	"back": "TXT_0465",
	"page": "TXT_0516",
}

const PAGE_TOP_FLAGS = {
	"id": &"top_flags", "title": "TXT_0952", "body": "TXT_0954",
	"preview": {"kind": &"top_hud", "field": &"flags"},
}

const PAGE_TOP_TIMER = {
	"id": &"top_timer", "title": "TXT_0953", "body": "TXT_0955",
	"preview": {"kind": &"top_hud", "field": &"timer"},
}

# Each page explains one decision; related UI stays together.
const PAGES = {
	&"land": [
		{
			"id": &"land_board", "title": "TXT_0881", "body": "TXT_0839",
			"preview": {"kind": &"group", "items": [
				{"preview": {"kind": &"cell", "theme": &"land", "state": &"hidden"}, "caption": "TXT_0615"},
				{"preview": {"kind": &"cell", "theme": &"land", "state": &"flagged"}, "caption": "TXT_0618"},
			]},
			"mouse": "TXT_0830", "keyboard": "TXT_0831",
		},
		{
			"id": &"land_number", "title": "TXT_0882", "body": "TXT_0840",
			"preview": {"kind": &"grid", "theme": &"land", "preset": &"neighbors"},
		},
		{
			"id": &"land_chord", "title": "TXT_0883", "body": "TXT_0888",
			"preview": {"kind": &"group", "items": [
				{"preview": {"kind": &"grid", "theme": &"land", "preset": &"expand_before"}, "caption": "TXT_0828"},
				{"preview": {"kind": &"grid", "theme": &"land", "preset": &"expand_after"}, "caption": "TXT_0829"},
			]},
			"mouse": "TXT_0889", "keyboard": "TXT_0890",
		},
		PAGE_TOP_FLAGS,
		PAGE_TOP_TIMER,
		{
			"id": &"land_info", "title": "TXT_0826", "body": "TXT_0841",
			"preview": {"kind": &"readout", "wide": true, "lines": [
				{"text": "TXT_0112"},
				{"text": "TXT_0117", "args": [1, 3]},
				{"text": "TXT_0156"},
				{"text": "TXT_0131"},
			]},
		},
		{
			"id": &"land_charge", "title": "TXT_0884", "body": "TXT_0885",
			"preview": {"kind": &"meter", "path": ART.LAND_V2_ROBOT_RIGHT_FRONT},
		},
		{
			"id": &"land_probe", "title": "TXT_0886", "body": "TXT_0887",
			"preview": {"kind": &"group", "items": [
				{"preview": {"kind": &"cell", "theme": &"land", "state": &"scan_target"}, "caption": "TXT_0837"},
				{"preview": {"kind": &"cell", "theme": &"land", "state": &"confirmed"}, "caption": "TXT_0838"},
			]},
			"mouse": "TXT_0650", "keyboard": "TXT_0651",
		},
		{
			"id": &"land_obstacle", "title": "TXT_0633", "body": "TXT_0845",
			"preview": {"kind": &"cell", "theme": &"land", "state": &"obstacle"},
		},
		{
			"id": &"land_nodule", "title": "TXT_0891", "body": "TXT_0842",
			"preview": {"kind": &"group", "items": [
				{"preview": {"kind": &"cell", "theme": &"land", "state": &"nodule"}, "caption": "TXT_0635"},
				{"preview": {"kind": &"texture", "path": ART.LAND_V2_POLLUTION_NODE_CLEANSED}, "caption": "TXT_0844"},
			]},
		},
		{
			"id": &"land_regrowth", "title": "TXT_0892", "body": "TXT_0893",
			"preview": {"kind": &"readout", "wide": true, "lines": [
				{"text": "TXT_0156"},
				{"text": "TXT_0481", "args": [15]},
			]},
		},
		{
			"id": &"ancient_root", "title": "TXT_0846", "body": "TXT_0843",
			"preview": {"kind": &"group", "items": [
				{"preview": {"kind": &"cell", "theme": &"land", "state": &"root"}, "caption": "TXT_0642"},
				{"preview": {"kind": &"texture", "path": ART.LAND_V2_ROOT_CLEANSED_STRAIGHT}, "caption": "TXT_0844"},
			]},
		},
	],
	&"ocean": [
		{
			"id": &"ocean_board", "title": "TXT_0881", "body": "TXT_0847",
			"preview": {"kind": &"group", "items": [
				{"preview": {"kind": &"cell", "theme": &"ocean", "state": &"hidden"}, "caption": "TXT_0654"},
				{"preview": {"kind": &"cell", "theme": &"ocean", "state": &"flagged"}, "caption": "TXT_0657"},
			]},
			"mouse": "TXT_0830", "keyboard": "TXT_0831",
		},
		{
			"id": &"ocean_number", "title": "TXT_0882", "body": "TXT_0848",
			"preview": {"kind": &"grid", "theme": &"ocean", "preset": &"neighbors"},
		},
		{
			"id": &"ocean_chord", "title": "TXT_0883", "body": "TXT_0888",
			"preview": {"kind": &"group", "items": [
				{"preview": {"kind": &"grid", "theme": &"ocean", "preset": &"expand_before"}, "caption": "TXT_0828"},
				{"preview": {"kind": &"grid", "theme": &"ocean", "preset": &"expand_after"}, "caption": "TXT_0829"},
			]},
			"mouse": "TXT_0889", "keyboard": "TXT_0890",
		},
		PAGE_TOP_FLAGS,
		PAGE_TOP_TIMER,
		{
			"id": &"ocean_info", "title": "TXT_0826", "body": "TXT_0849",
			"preview": {"kind": &"readout", "wide": true, "lines": [
				{"text": "TXT_0112"},
				{"text": "TXT_0122", "args": [1, 3]},
				{"text": "TXT_0156"},
				{"text": "TXT_0131"},
			]},
		},
		{
			"id": &"ocean_charge", "title": "TXT_0884", "body": "TXT_0885",
			"preview": {"kind": &"meter", "path": ART.OCEAN_V2_ROBOT_RIGHT_FRONT},
		},
		{
			"id": &"ocean_probe", "title": "TXT_0886", "body": "TXT_0887",
			"preview": {"kind": &"group", "items": [
				{"preview": {"kind": &"cell", "theme": &"ocean", "state": &"scan_target"}, "caption": "TXT_0837"},
				{"preview": {"kind": &"cell", "theme": &"ocean", "state": &"confirmed"}, "caption": "TXT_0838"},
			]},
			"mouse": "TXT_0650", "keyboard": "TXT_0651",
		},
		{
			"id": &"reef_wall", "title": "TXT_0665", "body": "TXT_0850",
			"preview": {"kind": &"texture", "path": ART.OCEAN_REEF_STRIP_FULL},
		},
		{
			"id": &"floating_buoy", "title": "TXT_0894", "body": "TXT_0851",
			"preview": {"kind": &"cell", "theme": &"ocean", "state": &"floating"},
		},
		{
			"id": &"buoy_drift", "title": "TXT_0895", "body": "TXT_0896",
			"preview": {"kind": &"group", "items": [
				{"preview": {"kind": &"readout", "lines": [
					{"text": "TXT_0156"},
					{"text": "TXT_0439", "args": [1, 7]},
				]}},
				{"preview": {"kind": &"texture", "path": ART.OCEAN_V2_MINE_STOP_LINE}, "caption": "TXT_0674"},
			]},
		},
		{
			"id": &"tidal_cover", "title": "TXT_0897", "body": "TXT_0852",
			"preview": {"kind": &"group", "items": [
				{"preview": {"kind": &"cell", "theme": &"ocean", "state": &"tide"}, "caption": "TXT_0677"},
				{"preview": {"kind": &"readout", "lines": [
					{"text": "TXT_0112"},
					{"text": "TXT_0122", "args": [1, 3]},
				]}},
			]},
		},
		{
			"id": &"tidal_numbers", "title": "TXT_0898", "body": "TXT_0899",
			"preview": {"kind": &"group", "items": [
				{"preview": {"kind": &"cell", "theme": &"ocean", "state": &"number", "number": 1}, "caption": "TXT_0900"},
				{"preview": {"kind": &"cell", "theme": &"ocean", "state": &"number", "number": 2}, "caption": "TXT_0901"},
			]},
		},
	],
	&"sky": [
		{
			"id": &"sky_sphere", "title": "TXT_0855", "body": "TXT_0856",
			"preview": {"kind": &"texture", "path": "res://assets/art/sky_levels/board/pentagon_hidden_surface.png"},
			"mouse": "TXT_0857", "keyboard": "TXT_0858",
		},
		{
			"id": &"sky_reveal_flag", "title": "TXT_0881", "body": "TXT_0940",
			"preview": {"kind": &"group", "items": [
				{"preview": {"kind": &"texture", "path": "res://assets/art/sky_levels/board/pentagon_hidden_surface.png"}, "caption": "TXT_0691"},
				{"preview": {"kind": &"texture", "path": ART.SKY_V2_MARKER}, "caption": "TXT_0696"},
			]},
			"mouse": "TXT_0830", "keyboard": "TXT_0941",
		},
		{
			"id": &"sky_number", "title": "TXT_0882", "body": "TXT_0859",
			"preview": {"kind": &"group", "items": [
				{"preview": {"kind": &"texture", "path": ART.SKY_V2_DIGIT_PATHS[1]}, "caption": "TXT_0694"},
				{"preview": {"kind": &"texture", "path": "res://assets/art/sky_levels/board/pentagon_revealed_surface.png"}, "caption": "TXT_0800"},
			]},
		},
		{
			"id": &"sky_chord", "title": "TXT_0883", "body": "TXT_0888",
			"preview": {"kind": &"group", "items": [
				{"preview": {"kind": &"texture", "path": ART.SKY_V2_DIGIT_PATHS[0]}, "caption": "TXT_0694"},
				{"preview": {"kind": &"texture", "path": ART.SKY_V2_MARKER}, "caption": "TXT_0696"},
			]},
			"mouse": "TXT_0889", "keyboard": "TXT_0890",
		},
		PAGE_TOP_FLAGS,
		PAGE_TOP_TIMER,
		{
			"id": &"sky_info", "title": "TXT_0826", "body": "TXT_0860",
			"preview": {"kind": &"readout", "wide": true, "lines": [
				{"text": "TXT_0112"},
				{"text": "TXT_0126", "args": [1, 3]},
				{"text": "TXT_0156"},
				{"text": "TXT_0131"},
			]},
		},
		{
			"id": &"sky_probe_charge", "title": "TXT_0884", "body": "TXT_0885",
			"preview": {"kind": &"meter", "path": ART.SKY_PROTAGONIST_ROBOT},
		},
		{
			"id": &"sky_probe", "title": "TXT_0886", "body": "TXT_0956",
			"preview": {"kind": &"group", "items": [
				{"preview": {"kind": &"texture", "path": "res://assets/art/sky_levels/board/pentagon_hidden_surface.png"}, "caption": "TXT_0837"},
				{"preview": {"kind": &"texture", "path": ART.SKY_V2_MARKER}, "caption": "TXT_0838"},
			]},
			"mouse": "TXT_0650", "keyboard": "TXT_0651",
		},
		{
			"id": &"sky_breeze", "title": "TXT_0704", "body": "TXT_0705",
			"preview": {"kind": &"sky_effect", "variant": &"breeze"},
		},
		{
			"id": &"sky_shield", "title": "TXT_0707", "body": "TXT_0708",
			"preview": {"kind": &"sky_effect", "variant": &"shield"},
		},
		{
			"id": &"storm_eye", "title": "TXT_0864", "body": "TXT_0863",
			"preview": {"kind": &"group", "items": [
				{"preview": {"kind": &"texture", "path": ART.SKY_V2_STORM_EYE_BODY}, "caption": "TXT_0710"},
				{"preview": {"kind": &"sky_effect", "variant": &"eye_arrow"}, "caption": "TXT_0712"},
			]},
			"mouse": "TXT_0713", "keyboard": "TXT_0714",
		},
		{
			"id": &"storm_eye_cleanse", "title": "TXT_0942", "body": "TXT_0943",
			"preview": {"kind": &"group", "items": [
				{"preview": {"kind": &"texture", "path": ART.SKY_V2_STORM_EYE_BODY}, "caption": "TXT_0710"},
				{"preview": {"kind": &"readout", "lines": [
					{"text": "TXT_0112"},
					{"text": "TXT_0126", "args": [1, 3]},
				]}},
			]},
		},
	],
	&"universe": [
		{
			"id": &"star_map", "title": "TXT_0865", "body": "TXT_0866",
			"preview": {"kind": &"group", "items": [
				{"preview": {"kind": &"links", "variant": &"normal", "state": &"hidden"}, "caption": "TXT_0724"},
				{"preview": {"kind": &"links", "variant": &"normal", "state": &"flagged"}, "caption": "TXT_0729"},
			]},
			"mouse": "TXT_0867",
		},
		{
			"id": &"star_links", "title": "TXT_0868", "body": "TXT_0869",
			"preview": {"kind": &"group", "items": [
				{"preview": {"kind": &"links", "variant": &"normal", "hub": true}, "caption": "TXT_0735"},
				{"preview": {"kind": &"links", "variant": &"bridge"}, "caption": "TXT_0737"},
				{"preview": {"kind": &"links", "variant": &"wormhole"}, "caption": "TXT_0740"},
			]},
		},
		{
			"id": &"star_chord", "title": "TXT_0883", "body": "TXT_0944",
			"preview": {"kind": &"group", "items": [
				{"preview": {"kind": &"links", "variant": &"normal", "state": &"number", "number": 1}, "caption": "TXT_0727"},
				{"preview": {"kind": &"links", "variant": &"normal", "state": &"flagged"}, "caption": "TXT_0729"},
			]},
			"mouse": "TXT_0945",
		},
		{
			"id": &"star_shield", "title": "TXT_0741", "body": "TXT_0742",
			"preview": {"kind": &"group", "items": [
				{"preview": {"kind": &"links", "variant": &"normal", "state": &"shield"}, "caption": "TXT_0741"},
				{"preview": {"kind": &"links", "variant": &"normal", "state": &"flagged"}, "caption": "TXT_0838"},
			]},
		},
		{
			"id": &"star_shield_recovery", "title": "TXT_0946", "body": "TXT_0947",
			"preview": {"kind": &"readout", "wide": true, "lines": [
				{"text": "TXT_0342", "args": [7]},
				{"text": "TXT_0338", "args": [2, 2]},
			]},
		},
		{
			"id": &"expedition_info", "title": "TXT_0870", "body": "TXT_0871",
			"preview": {"kind": &"readout", "wide": true, "lines": [
				{"text": "TXT_0340", "args": [2, 8]},
				{"text": "TXT_0342", "args": [3]},
				{"text": "TXT_0346", "args": [1200]},
			]},
		},
		{
			"id": &"expedition_restart", "title": "TXT_0948", "body": "TXT_0949",
			"preview": {"kind": &"readout", "wide": true, "lines": [
				{"text": "TXT_0342", "args": [0]},
				{"text": "TXT_0338", "args": [2, 2]},
			]},
		},
	],
	&"menus": [
		{
			"id": &"map_node", "title": "TXT_0873", "body": "TXT_0874",
			"preview": {"kind": &"group", "items": [
				{"preview": {"kind": &"texture", "path": ART.LEVEL_SELECT_MARKER_BUTTON}, "caption": "TXT_0548"},
				{"preview": {"kind": &"readout", "lines": [{"text": "TXT_0071"}]}},
			]},
			"mouse": "TXT_0550", "keyboard": "TXT_0551",
		},
		{
			"id": &"badge_book", "title": "TXT_0875", "body": "TXT_0876",
			"preview": {"kind": &"group", "items": [
				{"preview": {"kind": &"texture", "path": ART.LAND_BADGE_BOOK}, "caption": "TXT_0463"},
				{"preview": {"kind": &"texture", "path": ART.LAND_BADGE_PAGE_TURN}, "caption": "TXT_0470"},
			]},
			"mouse": "TXT_0586", "keyboard": "TXT_0587",
		},
		{
			"id": &"badge_hall", "title": "TXT_0470", "body": "TXT_0950",
			"preview": {"kind": &"group", "items": [
				{"preview": {"kind": &"texture", "path": ART.BADGE_HALL_LAND_BOOK_COVER}, "caption": "TXT_0590"},
				{"preview": {"kind": &"texture", "path": ART.BADGE_HALL_UNIVERSE_STAGE}, "caption": "TXT_0598"},
			]},
			"mouse": "TXT_0951", "keyboard": "TXT_0606",
		},
		{
			"id": &"opening_help", "title": "TXT_0879", "body": "TXT_0880",
			"preview": {"kind": &"group", "items": [
				{"preview": {"kind": &"texture", "path": ART.TUTORIAL_GUIDE_ROBOT_AVATAR}, "caption": "TXT_0629"},
			]},
		},
	],
}
