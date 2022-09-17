local Translations = {
    error = {
        canceled = '已取消',
        bled_out = '你已經失血過多...',
        impossible = '沒辦法做這件事...',
        no_player = '附近沒有人',
        no_firstaid = '你需要一個「急救包」',
        no_bandage = '你需要一個「繃帶」',
        beds_taken = '床位已被占用...',
        possessions_taken = 'All your possessions have been taken...',
        not_enough_money = '你的錢不夠...',
        cant_help = '你幫不了他...',
        not_ems = '你不是 EMS 或者沒有打卡上班',
        not_online = '該玩家不在線'
    },
    success = {
        revived = '你救起他了',
        healthy_player = '他身體很健康',
        helped_player = '你已經治療他了',
        wounds_healed = '你的傷口已經癒合!',
        being_helped = '你正在接受治療...'
    },
    info = {
        civ_died = 'Civilian Died',
        civ_down = 'Civilian Down',
        civ_call = '市民來電',
        self_death = '自己 或 NPC',
        wep_unknown = '未知',
        respawn_txt = '再 ~r~%{deathtime}~s~ 秒可以自主就醫',
        respawn_revive = '按住 [~r~E~s~] %{holdtime} 秒並支付 $~r~%{cost}~s~ 元回到醫院',
        bleed_out = '你將於 ~r~%{time}~s~ 秒後昏迷',
        bleed_out_help = '你將於 ~r~%{time}~s~ 秒後昏迷',
        request_help = '按 [~r~F3~s~] 尋求救援',
        help_requested = 'EMS PERSONNEL HAVE BEEN NOTIFIED',
        amb_plate = 'AMBU', -- Should only be 4 characters long due to the last 4 being a random 4 digits
        heli_plate = 'LIFE',  -- Should only be 4 characters long due to the last 4 being a random 4 digits
        status = '檢查傷勢',
        is_staus = 'Is %{status}',
        healthy = '你已經完全康復了!',
        safe = '醫院藥櫃',
        pb_hospital = '圓帽山醫院',
        pain_message = '你的%{limb}%{severity}',
        many_places = '你身上有多處疼痛...',
        bleed_alert = '%{bleedstate}',
        ems_alert = 'EMS Alert - %{text}',
        mr = '先生',
        mrs = '女士',
        dr_needed = '圓帽山醫院有民眾按求助鈴，請到大廳協助處理',
        ems_report = 'EMS Report',
        message_sent = 'Message to be sent',
        check_health = 'Check a Players Health',
        heal_player = 'Heal a Player',
        revive_player = 'Revive a Player',
        revive_player_a = 'Revive A Player or Yourself (Admin Only)',
        player_id = 'Player ID (may be empty)',
        pain_level = 'Set Yours or A Players Pain Level (Admin Only)',
        kill = 'Kill A Player or Yourself (Admin Only)',
        heal_player_a = 'Heal A Player or Yourself (Admin Only)',
    },
    mail = {
        sender = '圓帽山醫院',
        subject = '醫療費用',
        message = '親愛的 %{lastname} %{gender} , <br /><br />這封電子郵件向您說明我們對您收取了本次就診的醫療費用，並以銀行帳戶直接扣款，如有任何疑問請洽圓帽山醫院櫃台詢問。<br />總費用為: <strong>$%{costs}</strong><br /><br />我們祝您早日康復!'
    },
    states = {
        irritated = '發炎',
        quite_painful = '相當痛苦',
        painful = '很痛',
        really_painful = '實在是太痛了',
        little_bleed = '流了點血...',
        bleed = '流血...',
        lot_bleed = '大量出血...',
        big_bleed = '血流不止...',
    },
    menu = {
        amb_vehicles = '圓帽山醫院車庫',
        status = '健康狀況',
        close = '⬅ 關閉選單',
    },
    text = {
        armory_button = '[E] - 藥櫃',
        armory = '藥櫃',
        stash = '置物櫃',
        veh_button = '車庫',
        veh_parking = '停車',
        bed_out = '[E] - 下床',
        check = '掛號',
        toggle_duty = '上/下班'
    },
    body = {
        head = '頭部',
        neck = '頸部',
        spine = '脊椎',
        upper_body = '上半身',
        lower_body = '下半身',
        left_arm = '左手臂',
        left_hand = '左手',
        left_fingers = '左手手指',
        left_leg = '左腿',
        left_foot = '左腳',
        right_arm = '右手臂',
        right_hand = '右手',
        right_fingers = '右手手指',
        right_leg = '右腿',
        right_foot = '右腳',
    },
    progress = {
        ifaks = '使用 ifaks...',
        bandage = '使用繃帶...',
        painkillers = '使用 Painkillers...',
        revive = '復活...',
        healing = '治療傷口...',
        checking_in = '掛號...',
        status = '檢查傷勢...',
    },
    logs = {
        death_log_title = "%{playername} (%{playerid}) is dead",
        death_log_message = "%{killername} has killed %{playername} with a **%{weaponlabel}** (%{weaponname})",
    }
}

Lang = Lang or Locale:new({
    phrases = Translations,
    warnOnMissing = true
})