fx_version 'cerulean'
games { 'gta5' }

author 'Nguyễn Gia Khang'
description 'Pack Skin Vũ Khí & Cấu Hình Custom'
version '1.0.0'

-- Khai báo tất cả các file dữ liệu cấu hình sẽ được gửi xuống client
files {
    '*.meta'
}

-- Cấu hình load data hệ thống vũ khí từ các file meta
data_file 'WEAPONCOMPONENTSINFO_FILE' 'weaponcomponents.meta'
data_file 'WEAPON_METADATA_FILE' 'weaponarchetypes.meta'
data_file 'WEAPON_ANIMATIONS_FILE' 'weaponanimations.meta'
data_file 'WEAPONINFO_FILE' 'weapons.meta'
data_file 'PED_PERSONALITY_FILE' 'pedpersonality.meta'