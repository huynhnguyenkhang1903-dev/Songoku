fx_version 'cerulean'
games { 'gta5' }

author 'Nguyễn Gia Khang'
description 'Pack Tổng Hợp Vũ Khí, Cấu Hình Chống Hack & Phụ Kiện Kawai'
version '2.0.0'

-- Khai báo danh sách các file cấu hình hệ thống gửi xuống client
files {
    'weapongusenberg.meta',
    'weaponhatchet.meta',
    'weaponbullpuprifle.meta',
    'weapons_bullpuprifle_mk2.meta',
    'weaponheavypistol.meta',
    'weaponspecialcarbine.meta',
    'weapons_assaultrifle_mk2.meta',
    
    'weaponmachinepistol.meta',
    'weaponcombatpdw.meta',
    'weaponminismg.meta',
    'weapons_pistol_mk2.meta',
    'weaponsnspistol.meta',
    'weaponcompactrifle.meta',
    'weapons_carbinerifle_mk2.meta',
    'weapons_specialcarbine_mk2.meta',
    'weaponrevolver.meta',
    'weaponautoshotgun.meta',
    'weaponsnowball.meta',
    'weaponmachete.meta',
    'weaponknuckle.meta',
    'weaponpoolcue.meta',
    
    'weapons.meta',
    'component.meta',
    'weaponcomponents_root.meta', -- anti hack
    'weaponcomponents_addon.meta', -- anti hack
    'archetype.meta',
}

-- Cấu hình load Metadata và file .ytyp trong thư mục stream
data_file 'WEAPON_METADATA_FILE' 'archetype.meta'
data_file 'DLC_ITYP_REQUEST' 'stream/nuis_metadata.ytyp'
data_file 'DLC_ITYP_REQUEST' 'stream/specialcarbineriflemk2_kawai.ytyp'
data_file 'DLC_ITYP_REQUEST' 'stream/assaultriflemk2_kawai.ytyp'
data_file 'DLC_ITYP_REQUEST' 'stream/carbineriflemk2_kawai.ytyp'
data_file 'DLC_ITYP_REQUEST' 'stream/w_kawai_extended.ytyp'

-- Cấu hình ghi đè thông số vũ khí (Weapon Info Patch)
data_file 'WEAPONINFO_FILE_PATCH' 'weapons.meta'
data_file 'WEAPONINFO_FILE_PATCH' 'weapons_assaultrifle_mk2.meta'
data_file 'WEAPONINFO_FILE_PATCH' 'weapongusenberg.meta'
data_file 'WEAPONINFO_FILE_PATCH' 'weaponhatchet.meta'
data_file 'WEAPONINFO_FILE_PATCH' 'weaponbullpuprifle.meta'
data_file 'WEAPONINFO_FILE_PATCH' 'weaponheavypistol.meta'
data_file 'WEAPONINFO_FILE_PATCH' 'weaponspecialcarbine.meta'
data_file 'WEAPONINFO_FILE_PATCH' 'weapons_bullpuprifle_mk2.meta'

data_file 'WEAPONINFO_FILE_PATCH' 'weaponmachinepistol.meta'
data_file 'WEAPONINFO_FILE_PATCH' 'weaponcombatpdw.meta'
data_file 'WEAPONINFO_FILE_PATCH' 'weaponminismg.meta'
data_file 'WEAPONINFO_FILE_PATCH' 'weapons_pistol_mk2.meta'
data_file 'WEAPONINFO_FILE_PATCH' 'weaponsnspistol.meta'
data_file 'WEAPONINFO_FILE_PATCH' 'weaponcompactrifle.meta'

data_file 'WEAPONINFO_FILE_PATCH' 'weapons_carbinerifle_mk2.meta'
data_file 'WEAPONINFO_FILE_PATCH' 'weaponrevolver.meta'
data_file 'WEAPONINFO_FILE_PATCH' 'weaponautoshotgun.meta'
data_file 'WEAPONINFO_FILE_PATCH' 'weaponsnowball.meta'
data_file 'WEAPONINFO_FILE_PATCH' 'weapons_specialcarbine_mk2.meta'

data_file 'WEAPONINFO_FILE_PATCH' 'weaponmachete.meta'
data_file 'WEAPONINFO_FILE_PATCH' 'weaponknuckle.meta'
data_file 'WEAPONINFO_FILE_PATCH' 'weaponpoolcue.meta'

-- Cấu hình linh kiện súng (Weapon Components) và các mục quét bổ sung
data_file 'WEAPONCOMPONENTSINFO_FILE' 'component.meta'
data_file 'WEAPONCOMPONENTSINFO_FILE' 'weaponcomponents_root.meta'
data_file 'WEAPONCOMPONENTSINFO_FILE' 'weaponcomponents_addon.meta'
