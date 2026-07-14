fx_version 'cerulean'
game 'gta5'

author 'GTA5VN'
description 'He Thong Quan Ly NPC'

-- Cách 1: Nếu NativeUI là một resource chạy độc lập trên server
client_scripts {
    '@NativeUI/NativeUI.lua', -- Đảm bảo thư mục NativeUI đang chạy trên server
    'client.lua'              -- File chứa code của bạn
}