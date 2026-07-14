Config = {}

-- Key to toggle the menu (F5 key by default, bound via RegisterKeyMapping)
Config.MenuKey = "F5"

Config.Emotes = {
    -- Actions
    {
        id = "wave",
        label = "Vẫy tay",
        category = "actions",
        type = "animation",
        dict = "friends@",
        anim = "wave",
        flag = 49 -- Upper body, looping, can walk
    },
    {
        id = "salute",
        label = "Chào kiểu quân đội",
        category = "actions",
        type = "animation",
        dict = "anim@mp_player_intuppersalute",
        anim = "idle_a",
        flag = 49
    },
    {
        id = "cross_arms",
        label = "Khoanh tay",
        category = "actions",
        type = "animation",
        dict = "amb@world_human_cop_idles@male@idle_b",
        anim = "idle_d",
        flag = 49
    },
    {
        id = "think",
        label = "Suy nghĩ",
        category = "actions",
        type = "animation",
        dict = "amb@code_human_police_investigate@idle_a",
        anim = "idle_b",
        flag = 49
    },
    {
        id = "facepalm",
        label = "Bó tay (Facepalm)",
        category = "actions",
        type = "animation",
        dict = "anim@mp_player_intupperface_palm",
        anim = "idle_a",
        flag = 49
    },
    {
        id = "shrug",
        label = "Nhún vai",
        category = "actions",
        type = "animation",
        dict = "anim@mp_player_intuppershrug",
        anim = "idle_a",
        flag = 49
    },
    {
        id = "cheer",
        label = "Vui mừng",
        category = "actions",
        type = "animation",
        dict = "amb@world_human_cheering@male_a",
        anim = "base",
        flag = 1 -- Loop, full body
    },
    {
        id = "laugh",
        label = "Cười lớn",
        category = "actions",
        type = "animation",
        dict = "anim@mp_player_intupperlaughter",
        anim = "idle_a",
        flag = 49
    },
    {
        id = "surrender",
        label = "Giơ tay đầu hàng",
        category = "actions",
        type = "animation",
        dict = "random@arrests@busted",
        anim = "idle_a",
        flag = 49
    },

    -- Postures (Tư thế)
    {
        id = "sit_ground",
        label = "Ngồi bệt",
        category = "postures",
        type = "animation",
        dict = "anim@heists@fleeca_bank@ig_7_jetski_owner",
        anim = "owner_idle",
        flag = 1 -- Full body loop
    },
    {
        id = "lay_back",
        label = "Nằm ngửa",
        category = "postures",
        type = "animation",
        dict = "amb@world_human_sunbathe@male@back@idle_a",
        anim = "idle_a",
        flag = 1
    },
    {
        id = "lay_side",
        label = "Nằm nghiêng",
        category = "postures",
        type = "animation",
        dict = "amb@world_human_sunbathe@male@front@idle_a",
        anim = "idle_a",
        flag = 1
    },
    {
        id = "lean_wall",
        label = "Dựa tường",
        category = "postures",
        type = "animation",
        dict = "amb@loiter@car@default@female_xs@base",
        anim = "base",
        flag = 1
    },
    {
        id = "yoga",
        label = "Tập Yoga",
        category = "postures",
        type = "scenario",
        scenario = "WORLD_HUMAN_YOGA"
    },
    {
        id = "flex",
        label = "Khoe cơ bắp",
        category = "postures",
        type = "scenario",
        scenario = "PROP_HUMAN_MUSCLE_FLEX"
    },
    {
        id = "guard",
        label = "Đứng gác",
        category = "postures",
        type = "scenario",
        scenario = "WORLD_HUMAN_SECURITY_GUARD"
    },

    -- Dances (Điệu nhảy)
    {
        id = "dance_party",
        label = "Nhảy Party",
        category = "dances",
        type = "animation",
        dict = "amb@world_human_partying@female@partying_beer@base",
        anim = "base",
        flag = 1
    },
    {
        id = "dance_tao",
        label = "Nhảy điệu Tao",
        category = "dances",
        type = "animation",
        dict = "misschinese2_crystalmazemcs1_ig",
        anim = "dance_loop_tao",
        flag = 1
    },
    {
        id = "dance_snitch",
        label = "Nhảy điệu Snitch",
        category = "dances",
        type = "animation",
        dict = "missfbi3_snitch",
        anim = "dance_loop_a",
        flag = 1
    },
    {
        id = "dance_nigel",
        label = "Nhảy vui nhộn",
        category = "dances",
        type = "animation",
        dict = "rcmnigel1b",
        anim = "dance_loop_a",
        flag = 1
    },
    {
        id = "dance_club",
        label = "Nhảy Vũ Trường",
        category = "dances",
        type = "animation",
        dict = "mini@strip_club@private_dance@part1",
        anim = "priv_dance_p1",
        flag = 1
    },

    -- Scenarios (Vật phẩm/Ngữ cảnh)
    {
        id = "smoke",
        label = "Hút thuốc lá",
        category = "scenarios",
        type = "scenario",
        scenario = "WORLD_HUMAN_SMOKING"
    },
    {
        id = "drink_coffee",
        label = "Uống Cà phê",
        category = "scenarios",
        type = "scenario",
        scenario = "WORLD_HUMAN_DRINKING"
    },
    {
        id = "use_phone",
        label = "Dùng điện thoại",
        category = "scenarios",
        type = "scenario",
        scenario = "WORLD_HUMAN_STAND_MOBILE"
    },
    {
        id = "drink_beer",
        label = "Uống bia",
        category = "scenarios",
        type = "scenario",
        scenario = "PROP_HUMAN_SEAT_BAR"
    },
    {
        id = "clipboard",
        label = "Xem bảng ghi",
        category = "scenarios",
        type = "scenario",
        scenario = "WORLD_HUMAN_CLIPBOARD"
    },
    {
        id = "binoculars",
        label = "Nhìn ống nhòm",
        category = "scenarios",
        type = "scenario",
        scenario = "WORLD_HUMAN_BINOCULARS"
    },
    {
        id = "bbq",
        label = "Nướng thịt BBQ",
        category = "scenarios",
        type = "scenario",
        scenario = "PROP_HUMAN_BBQ"
    },

    -- Combat - Attacks (Tấn công)
    {
        id = "punch_left",
        label = "Đấm thẳng trái",
        category = "combat_atk",
        type = "animation",
        dict = "melee@unarmed@streamed_variations",
        anim = "punch_left",
        flag = 49,
        react = { dict = "melee@unarmed@streamed_variations", anim = "hit_right_heavy", flag = 0 }
    },
    {
        id = "punch_right",
        label = "Đấm thẳng phải",
        category = "combat_atk",
        type = "animation",
        dict = "melee@unarmed@streamed_variations",
        anim = "punch_right",
        flag = 49,
        react = { dict = "melee@unarmed@streamed_variations", anim = "hit_left_heavy", flag = 0 }
    },
    {
        id = "punch_left_heavy",
        label = "Đấm móc trái",
        category = "combat_atk",
        type = "animation",
        dict = "melee@unarmed@streamed_variations",
        anim = "punch_left_heavy",
        flag = 49,
        react = { dict = "melee@unarmed@streamed_variations", anim = "hit_back_heavy", flag = 0 }
    },
    {
        id = "punch_right_heavy",
        label = "Đấm móc phải",
        category = "combat_atk",
        type = "animation",
        dict = "melee@unarmed@streamed_variations",
        anim = "punch_right_heavy",
        flag = 49,
        react = { dict = "melee@unarmed@streamed_variations", anim = "hit_back_heavy", flag = 0 }
    },
    {
        id = "punch_combo",
        label = "Đấm liên hoàn",
        category = "combat_atk",
        type = "animation",
        dict = "melee@combat@boxing@punch_combo",
        anim = "punch_combo_a",
        flag = 49,
        react = { dict = "melee@combat@boxing@punch_combo", anim = "react_punch_combo_a", flag = 0 }
    },
    {
        id = "kick_left",
        label = "Đá thẳng trái",
        category = "combat_atk",
        type = "animation",
        dict = "melee@unarmed@streamed_variations",
        anim = "kick_left",
        flag = 0,
        react = { dict = "melee@unarmed@streamed_variations", anim = "hit_gut", flag = 0 }
    },
    {
        id = "kick_right",
        label = "Đá thẳng phải",
        category = "combat_atk",
        type = "animation",
        dict = "melee@unarmed@streamed_variations",
        anim = "kick_right",
        flag = 0,
        react = { dict = "melee@unarmed@streamed_variations", anim = "hit_gut", flag = 0 }
    },
    {
        id = "kick_sweep",
        label = "Đá quét chân",
        category = "combat_atk",
        type = "animation",
        dict = "melee@kick@kick_slap",
        anim = "kick_slap_a",
        flag = 0,
        react = { dict = "move_jump", anim = "wall_roll_l", flag = 0 }
    },
    {
        id = "punch_spin",
        label = "Đấm xoay người",
        category = "combat_atk",
        type = "animation",
        dict = "melee@combat@boxing@kick_slap",
        anim = "slap_base_a",
        flag = 0,
        react = { dict = "damage@kick@kick_slap", anim = "kick_slap_react", flag = 0 }
    },
    {
        id = "slap_heavy",
        label = "Tát nảy lửa",
        category = "combat_atk",
        type = "animation",
        dict = "melee@unarmed@streamed_variations",
        anim = "slap_heavy",
        flag = 49,
        react = { dict = "misscarsteal4@director_shot", anim = "react_punch", flag = 0 }
    },
    {
        id = "block_left",
        label = "Gạt tay đỡ trái",
        category = "combat_atk",
        type = "animation",
        dict = "melee@unarmed@streamed_variations",
        anim = "block_left",
        flag = 49,
        react = { dict = "melee@unarmed@streamed_variations", anim = "punch_left", flag = 49 }
    },
    {
        id = "block_right",
        label = "Gạt tay đỡ phải",
        category = "combat_atk",
        type = "animation",
        dict = "melee@unarmed@streamed_variations",
        anim = "block_right",
        flag = 49,
        react = { dict = "melee@unarmed@streamed_variations", anim = "punch_right", flag = 49 }
    },
    {
        id = "stealth_kill",
        label = "Móc cằm hạ gục",
        category = "combat_atk",
        type = "animation",
        dict = "melee@knife@streamed_variations",
        anim = "stealth_kill_atk",
        flag = 0,
        react = { dict = "melee@knife@streamed_variations", anim = "stealth_kill_def", flag = 0 }
    },
    {
        id = "punch_combo_b",
        label = "Đấm chỏ áp sát",
        category = "combat_atk",
        type = "animation",
        dict = "melee@combat@boxing@punch_combo",
        anim = "punch_combo_b",
        flag = 0,
        react = { dict = "damage@pain@male@heavy", anim = "pain_heavy_01", flag = 0 }
    },
    {
        id = "punch_elbow",
        label = "Đánh cùi chỏ",
        category = "combat_atk",
        type = "animation",
        dict = "melee@unarmed@streamed_variations",
        anim = "punch_elbow",
        flag = 49,
        react = { dict = "melee@unarmed@streamed_variations", anim = "hit_gut", flag = 0 }
    },

    -- Combat - Hits / Defends (Bị đòn / Đỡ)
    {
        id = "hit_back_heavy",
        label = "Bị đấm té ngửa",
        category = "combat_def",
        type = "animation",
        dict = "melee@unarmed@streamed_variations",
        anim = "hit_back_heavy",
        flag = 0
    },
    {
        id = "hit_left_heavy",
        label = "Bị đấm lệch trái",
        category = "combat_def",
        type = "animation",
        dict = "melee@unarmed@streamed_variations",
        anim = "hit_left_heavy",
        flag = 0
    },
    {
        id = "hit_right_heavy",
        label = "Bị đấm lệch phải",
        category = "combat_def",
        type = "animation",
        dict = "melee@unarmed@streamed_variations",
        anim = "hit_right_heavy",
        flag = 0
    },
    {
        id = "hit_gut",
        label = "Bị đấm trúng bụng",
        category = "combat_def",
        type = "animation",
        dict = "melee@unarmed@streamed_variations",
        anim = "hit_gut",
        flag = 0
    },
    {
        id = "kick_react",
        label = "Bị đá văng ngã",
        category = "combat_def",
        type = "animation",
        dict = "damage@kick@kick_slap",
        anim = "kick_slap_react",
        flag = 0
    },
    {
        id = "pain_heavy",
        label = "Đau đớn nặng",
        category = "combat_def",
        type = "animation",
        dict = "damage@pain@male@heavy",
        anim = "pain_heavy_01",
        flag = 0
    },
    {
        id = "pain_head",
        label = "Đau đớn ôm đầu",
        category = "combat_def",
        type = "animation",
        dict = "damage@pain@male@heavy",
        anim = "pain_heavy_02",
        flag = 0
    },
    {
        id = "pain_light",
        label = "Đau đớn nhẹ",
        category = "combat_def",
        type = "animation",
        dict = "damage@pain@male@light",
        anim = "pain_light_01",
        flag = 0
    },
    {
        id = "stungun_react",
        label = "Bị giật choáng",
        category = "combat_def",
        type = "animation",
        dict = "random@arrests",
        anim = "react_stungun",
        flag = 0
    },
    {
        id = "stunned",
        label = "Choáng váng lảo đảo",
        category = "combat_def",
        type = "animation",
        dict = "misscarsteal4@director_shot",
        anim = "react_punch",
        flag = 0
    },
    {
        id = "tasered",
        label = "Co giật cơ thể",
        category = "combat_def",
        type = "animation",
        dict = "missminuteman_1ig_2",
        anim = "tasered_1",
        flag = 0
    },
    {
        id = "wall_roll",
        label = "Ngã lăn lộn đất",
        category = "combat_def",
        type = "animation",
        dict = "move_jump",
        anim = "wall_roll_l",
        flag = 0
    },
    {
        id = "punch_react",
        label = "Đỡ đòn ôm mặt",
        category = "combat_def",
        type = "animation",
        dict = "melee@combat@boxing@punch_combo",
        anim = "react_punch_combo_a",
        flag = 0
    },
    {
        id = "block_react",
        label = "Né đòn ngả sau",
        category = "combat_def",
        type = "animation",
        dict = "melee@unarmed@streamed_variations",
        anim = "block_react",
        flag = 49
    },
    {
        id = "wounded_ground",
        label = "Nằm liệt đau đớn",
        category = "combat_def",
        type = "animation",
        dict = "missfbi5ig_21",
        anim = "wounded_idle_shamy",
        flag = 1
    },

    -- Combat - Choreography (Đấu võ tự động)
    {
        id = "choreo_sparring",
        label = "Đấu võ biểu diễn",
        category = "combat_choreo",
        type = "choreography",
        steps = {
            {
                attacker = { dict = "melee@unarmed@streamed_variations", anim = "punch_left", flag = 49 },
                victim = { dict = "melee@unarmed@streamed_variations", anim = "block_left", flag = 49 },
                delay = 900
            },
            {
                attacker = { dict = "melee@unarmed@streamed_variations", anim = "kick_right", flag = 0 },
                victim = { dict = "melee@unarmed@streamed_variations", anim = "hit_gut", flag = 0 },
                delay = 1200
            },
            {
                attacker = { dict = "melee@combat@boxing@punch_combo", anim = "react_punch_combo_a", flag = 0 },
                victim = { dict = "melee@combat@boxing@punch_combo", anim = "punch_combo_a", flag = 49 },
                delay = 1500
            },
            {
                attacker = { dict = "melee@unarmed@streamed_variations", anim = "punch_right_heavy", flag = 49 },
                victim = { dict = "melee@unarmed@streamed_variations", anim = "hit_back_heavy", flag = 0 },
                delay = 1500
            }
        }
    },
    {
        id = "choreo_street",
        label = "Quyết đấu đường phố",
        category = "combat_choreo",
        type = "choreography",
        steps = {
            {
                attacker = { dict = "melee@unarmed@streamed_variations", anim = "slap_heavy", flag = 49 },
                victim = { dict = "misscarsteal4@director_shot", anim = "react_punch", flag = 0 },
                delay = 1000
            },
            {
                attacker = { dict = "melee@unarmed@streamed_variations", anim = "hit_left_heavy", flag = 0 },
                victim = { dict = "melee@unarmed@streamed_variations", anim = "punch_right", flag = 49 },
                delay = 1000
            },
            {
                attacker = { dict = "melee@kick@kick_slap", anim = "kick_slap_a", flag = 0 },
                victim = { dict = "move_jump", anim = "wall_roll_l", flag = 0 },
                delay = 1500
            },
            {
                attacker = { dict = "amb@world_human_cheering@male_a", anim = "base", flag = 1 },
                victim = { dict = "missfbi5ig_21", anim = "wounded_idle_shamy", flag = 1 },
                delay = 2000
            }
        }
    }
}
