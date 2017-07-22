module TtuCode
  DEPS = {
    "V" => [
      {"code" =>  "V", "department" =>   "媒體系"},
      {"code" =>  "V1", "department" =>  "媒體設計學系 數位遊戲設計組"},
      {"code" =>  "V2", "department" =>  "媒體設計學系 互動媒體設計組"}
    ],

    "B" =>  [
      {"code" =>  "B", "department" =>   "事業經營學系"},
      {"code" =>  "BB", "department" =>  "事業經營學系"},
      {"code" =>  "BI", "department" =>  "事業經營研究所"},
      {"code" =>  "BM", "department" =>  "事業經營研究所碩士班"},
      {"code" =>  "BJ", "department" =>  "事業經營研究所碩士在職專班"}
    ],

    "I" => [
      {"code" =>  "I", "department" =>   "資訊工程學系"},
      {"code" =>  "IB", "department" =>  "資訊工程學系"},
      {"code" =>  "II", "department" =>  "資訊工程研究所"},
      {"code" =>  "IM", "department" =>  "資訊工程研究所碩士班"},
      {"code" =>  "ID", "department" =>  "資訊工程研究所博士班"},
      {"code" =>  "IJ", "department" =>  "資訊工程研究所碩士在職專班"}
    ],

    "S" =>  [
      {"code" =>  "S", "department" =>   "生物工程學系"},
      {"code" =>  "SB", "department" =>  "生物工程學系"},
      {"code" =>  "SI", "department" =>  "生物工程研究所"},
      {"code" =>  "SM", "department" =>  "生物工程研究所碩士班"},
      {"code" =>  "SD", "department" =>  "生物工程研究所博士班"},
      {"code" =>  "SJ", "department" =>  "生物工程研究所碩士在職專班"}
    ],

    "N" => [
      {"code" =>  "N", "department" =>   "資訊經營學系"},
      {"code" =>  "NB", "department" =>  "資訊經營系"},
      {"code" =>  "NI", "department" =>  "資訊經營研究所"},
      {"code" =>  "NM", "department" =>  "資訊經營研究所碩士班"},
      {"code" =>  "NJ", "department" =>  "資訊經營研究所碩士在職專班"}
    ],

    "T" => [
      {"code" =>  "T", "department" =>   "材料工程學系"},
      {"code" =>  "TB", "department" =>  "材料工程系"},
      {"code" =>  "TI", "department" =>  "材料工程研究所"},
      {"code" =>  "TM", "department" =>  "材料工程研究所碩士班"},
      {"code" =>  "TD", "department" =>  "材料工程研究所博士班"}
    ],

    "C" => [
      {"code" =>  "C", "department" =>    "化學工程學系"},
      {"code" =>  "CB", "department" =>   "化學工程系"},
      {"code" =>  "CI", "department" =>   "化學工程研究所"},
      {"code" =>  "CM", "department" =>   "化學工程研究所碩士班"},
      {"code" =>  "CD", "department" =>   "化學工程研究所博士班"}
    ],

    "M" => [
      {"code" =>  "M", "department" =>    "機械工程學系"},
      {"code" =>  "MB", "department" =>   "機械工程系"},
      {"code" =>  "M1", "department" =>   "機械工程學系 電子機械組"},
      {"code" =>  "M2", "department" =>   "機械工程學系 精密機械組"},
      {"code" =>  "MI", "department" =>   "機械工程研究所"},
      {"code" =>  "MM", "department" =>   "機械工程研究所碩士班"},
      {"code" =>  "MD", "department" =>   "機械工程研究所博士班"}
    ],

    "P" => [
      {"code" =>  "P", "department" =>   "能源科技碩士學位學程"},
      {"code" =>  "PC", "department" =>  "能源科技碩士學位學程班"}
    ],

    "O" => [
      {"code" =>  "O", "department" =>  "光電工程研究所"},
      {"code" =>  "OM", "department" =>  "光電工程研究所碩士班"},
      {"code" =>  "OD", "department" =>  "光電工程研究所博士班"}
    ],

    "D" => [
      {"code" =>  "D", "department" =>  "工業設計學系"},
      {"code" =>  "DB", "department" =>  "工業設計系"},
      {"code" =>  "DI", "department" =>  "工業設計研究所"},
      {"code" =>  "DM", "department" =>  "工業設計研究所碩士班"},
      {"code" =>  "DD", "department" =>  "工業設計研究所博士班"},
      {"code" =>  "DJ", "department" =>  "工業設計研究所碩士在職專班"}
    ],

    "K" => [
      {"code" =>  "K", "department" =>  "設計科學研究所"},
      {"code" =>  "KM", "department" =>  "設計科學研究所博士班"}
    ],

    "E" => [
      {"code" =>  "E", "department" =>    "電機工程學系"},
      {"code" =>  "EB", "department" =>   "電機工程系"},
      {"code" =>  "E1", "department" =>   "電機工程學系 電機與系統組"},
      {"code" =>  "E2", "department" =>   "電機工程學系 電子與通訊組"},
      {"code" =>  "EI", "department" =>   "電機工程研究所"},
      {"code" =>  "EM", "department" =>   "電機工程研究所碩士班"},
      {"code" =>  "ED", "department" =>   "電機工程研究所博士班"},
      {"code" =>  "EJ", "department" =>   "電機工程研究所碩士在職專班"}
    ],

    "W" => [
      {"code" =>  "W", "department" =>  "通訊工程研究所"},
      {"code" =>  "WM", "department" =>  "通訊工程研究所碩士班"},
      {"code" =>  "WD", "department" =>  "通訊工程研究所博士班"},
      {"code" =>  "WJ", "department" =>  "通訊工程研究所碩士在職專班"}
    ],

    "L" => [
      {"code" =>  "L", "department" =>  "應用外語學系"}
    ],

    "Q" =>  [
      {"code" =>  "Q", "department" =>  "工程管理學位學程"},
      {"code" =>  "QJ", "department" =>  "工程管理碩士在職專班"}
    ]
  }
end
