/**
 * Emoji Adapter - GitHub-compatible emoji shortcodes
 */

import type { EmojiPort } from "../../domain/ports";

// ============================================================================
// GitHub Emoji Map (subset - full list has 1500+)
// ============================================================================

const EMOJI_MAP: Record<string, string> = {
  // Smileys
  ":+1:": "👍",
  ":-1:": "👎",
  ":smile:": "😄",
  ":laughing:": "😆",
  ":blush:": "😊",
  ":smiley:": "😃",
  ":relaxed:": "☺️",
  ":smirk:": "😏",
  ":heart_eyes:": "😍",
  ":kissing_heart:": "😘",
  ":kissing_closed_eyes:": "😚",
  ":kissing:": "😗",
  ":kissing_smiling_eyes:": "😙",
  ":stuck_out_tongue_winking_eye:": "😜",
  ":stuck_out_tongue_closed_eyes:": "😝",
  ":stuck_out_tongue:": "😛",
  ":flushed:": "😳",
  ":grin:": "😁",
  ":pensive:": "😔",
  ":relieved:": "😌",
  ":unamused:": "😒",
  ":disappointed:": "😞",
  ":persevere:": "😣",
  ":cry:": "😢",
  ":joy:": "😂",
  ":sob:": "😭",
  ":scream:": "😱",
  ":angry:": "😠",
  ":rage:": "😡",
  ":triumph:": "😤",
  ":confused:": "😕",
  ":innocent:": "😇",
  ":alien:": "👽",
  ":yellow_heart:": "💛",
  ":blue_heart:": "💙",
  ":purple_heart:": "💜",
  ":green_heart:": "💚",
  ":heart:": "❤️",
  ":broken_heart:": "💔",
  ":fire:": "🔥",
  ":sparkles:": "✨",
  ":star:": "⭐",
  ":star2:": "🌟",
  ":zap:": "⚡",
  ":sunny:": "☀️",
  ":cloud:": "☁️",
  ":umbrella:": "☂️",
  ":snowflake:": "❄️",
  ":rainbow:": "🌈",
  
  // Objects
  ":rocket:": "🚀",
  ":airplane:": "✈️",
  ":car:": "🚗",
  ":bike:": "🚲",
  ":bus:": "🚌",
  ":train:": "火车",
  ":ship:": "🚢",
  ":computer:": "💻",
  ":phone:": "📱",
  ":email:": "📧",
  ":package:": "📦",
  ":lock:": "🔒",
  ":key:": "🔑",
  ":bulb:": "💡",
  ":wrench:": "🔧",
  ":hammer:": "🔨",
  ":gear:": "⚙️",
  ":link:": "🔗",
  ":mag:": "🔍",
  ":mag_right:": "🔎",
  
  // Symbols
  ":white_check_mark:": "✅",
  ":x:": "❌",
  ":heavy_check_mark:": "✔️",
  ":heavy_plus_sign:": "➕",
  ":heavy_minus_sign:": "➖",
  ":heavy_multiplication_x:": "✖️",
  ":heavy_division_sign:": "➗",
  ":warning:": "⚠️",
  ":bangbang:": "‼️",
  ":interrobang:": "⁉️",
  ":question:": "❓",
  ":exclamation:": "❗",
  ":grey_exclamation:": "❔",
  ":grey_question:": "❕",
  ":recycle:": "♻️",
  ":white_circle:": "⚪",
  ":black_circle:": "⚫",
  ":red_circle:": "🔴",
  ":blue_circle:": "🔵",
  ":green_circle:": "🟢",
  ":yellow_circle:": "🟡",
  ":purple_circle:": "🟣",
  ":orange_circle:": "🟠",
  
  // Hands
  ":thumbsup:": "👍",
  ":thumbsdown:": "👎",
  ":ok_hand:": "👌",
  ":punch:": "👊",
  ":fist:": "✊",
  ":v:": "✌️",
  ":wave:": "👋",
  ":clap:": "👏",
  ":raised_hands:": "🙌",
  ":pray:": "🙏",
  ":muscle:": "💪",
  
  // Food
  ":apple:": "🍎",
  ":green_apple:": "🍏",
  ":orange:": "🍊",
  ":lemon:": "🍋",
  ":banana:": "🍌",
  ":watermelon:": "🍉",
  ":grapes:": "🍇",
  ":strawberry:": "🍓",
  ":melon:": "🍈",
  ":cherries:": "🍒",
  ":peach:": "🍑",
  ":mango:": "🥭",
  ":pineapple:": "🍍",
  ":coconut:": "🥥",
  ":kiwi:": "🥝",
  ":tomato:": "🍅",
  ":eggplant:": "🍆",
  ":avocado:": "🥑",
  ":broccoli:": "🥦",
  ":carrot:": "🥕",
  ":corn:": "🌽",
  ":hot_pepper:": "🌶️",
  ":potato:": "🥔",
  ":sweet_potato:": "🍠",
  ":bread:": "🍞",
  ":cheese:": "🧀",
  ":egg:": "🥚",
  ":bacon:": "🥓",
  ":steak:": "🥩",
  ":poultry_leg:": "🍗",
  ":hamburger:": "🍔",
  ":fries:": "🍟",
  ":pizza:": "🍕",
  ":hotdog:": "🌭",
  ":sandwich:": "🥪",
  ":taco:": "🌮",
  ":burrito:": "🌯",
  ":salad:": "🥗",
  ":popcorn:": "🍿",
  
  // Drinks
  ":coffee:": "☕",
  ":tea:": "🍵",
  ":sake:": "🍶",
  ":beer:": "🍺",
  ":beers:": "🍻",
  ":wine_glass:": "🍷",
  ":cocktail:": "🍸",
  ":tropical_drink:": "🍹",
  ":champagne:": "🍾",
  
  // Activities
  ":soccer:": "⚽",
  ":basketball:": "🏀",
  ":football:": "🏈",
  ":baseball:": "⚾",
  ":tennis:": "🎾",
  ":volleyball:": "🏐",
  ":rugby_football:": "🏉",
  ":8ball:": "🎱",
  ":golf:": "⛳",
  ":golfer:": "🏌️",
  ":skiing:": "🎿",
  ":ice_skate:": "⛸️",
  ":bow_and_arrow:": "🏹",
  ":fishing_pole_and_fish:": "🎣",
  
  // Travel
  ":earth_africa:": "🌍",
  ":earth_americas:": "🌎",
  ":earth_asia:": "🌏",
  ":globe_with_meridians:": "🌐",
  ":world_map:": "🗺️",
  ":mountain:": "⛰️",
  ":mountain_snow:": "🏔️",
  ":camping:": "🏕️",
  ":beach_umbrella:": "🏖️",
  ":desert:": "🏜️",
  ":island:": "🏝️",
  ":volcano:": "🌋",
  ":milky_way:": "🌌",
  ":stars:": "🌠",
  ":night_with_stars:": "🌃",
  ":city_sunrise:": "🌅",
  ":city_sunset:": "🌇",
  ":bridge_at_night:": "🌉",
  
  // Objects
  ":watch:": "⌚",
  ":iphone:": "📱",
  ":calling:": "📲",
  ":computer:": "💻",
  ":keyboard:": "⌨️",
  ":desktop_computer:": "🖥️",
  ":printer:": "🖨️",
  ":mouse:": "🖱️",
  ":trackball:": "🖲️",
  ":joystick:": "🕹️",
  ":minidisc:": "💽",
  ":floppy_disk:": "💾",
  ":cd:": "💿",
  ":dvd:": "📀",
  ":vhs:": "📼",
  ":camera:": "📷",
  ":camera_flash:": "📸",
  ":video_camera:": "📹",
  ":movie_camera:": "🎥",
  ":projector:": "📽️",
  ":film_projector:": "🎞️",
  ":film_strip:": "🎞️",
  ":tv:": "📺",
  ":radio:": "📻",
  ":microphone:": "🎤",
  ":headphones:": "🎧",
  ":musical_score:": "🎼",
  ":musical_note:": "🎵",
  ":notes:": "🎶",
  ":musical_keyboard:": "🎹",
  ":drum:": "🥁",
  ":saxophone:": "🎷",
  ":trumpet:": "🎺",
  ":guitar:": "🎸",
  ":violin:": "🎻",
  
  // Symbols continued
  ":copyright:": "©️",
  ":registered:": "®️",
  ":tm:": "™️",
  ":hash:": "#️⃣",
  ":asterisk:": "*️⃣",
  ":zero:": "0️⃣",
  ":one:": "1️⃣",
  ":two:": "2️⃣",
  ":three:": "3️⃣",
  ":four:": "4️⃣",
  ":five:": "5️⃣",
  ":six:": "6️⃣",
  ":seven:": "7️⃣",
  ":eight:": "8️⃣",
  ":nine:": "9️⃣",
  ":keycap_ten:": "🔟",
  ":1234:": "🔢",
  ":arrow_right:": "➡️",
  ":arrow_left:": "⬅️",
  ":arrow_up:": "⬆️",
  ":arrow_down:": "⬇️",
  ":arrow_upper_right:": "↗️",
  ":arrow_lower_right:": "↘️",
  ":arrow_lower_left:": "↙️",
  ":arrow_upper_left:": "↖️",
  ":arrow_up_down:": "↕️",
  ":left_right_arrow:": "↔️",
  ":arrows_counterclockwise:": "🔄",
  ":arrow_backward:": "◀️",
  ":arrow_forward:": "▶️",
  ":arrow_up_small:": "🔼",
  ":arrow_down_small:": "🔽",
  
  // GitHub-specific
  ":octocat:": "🐙",
  ":shipit:": "🐿️",
};

// ============================================================================
// Emoji Adapter Implementation
// ============================================================================

export class EmojiAdapter implements EmojiPort {
  private reverseMap: Map<string, string>;

  constructor() {
    this.reverseMap = new Map();
    for (const [shortcode, char] of Object.entries(EMOJI_MAP)) {
      this.reverseMap.set(char, shortcode);
    }
  }

  getChar(shortcode: string): string | null {
    return EMOJI_MAP[shortcode] || null;
  }

  getShortcode(char: string): string | null {
    return this.reverseMap.get(char) || null;
  }

  getAll(): Map<string, string> {
    return new Map(Object.entries(EMOJI_MAP));
  }

  // Process text and replace emoji shortcodes
  processText(text: string): string {
    return text.replace(/:([a-zA-Z0-9_]+):/g, (match, shortcode) => {
      const char = EMOJI_MAP[`:${shortcode}:`];
      return char || match;
    });
  }
}
