# ArWoW Chat

<!-- Images can be placed here once hosted online -->
![Chat 1](https://cdn.discordapp.com/attachments/956515329608151121/1500637904957997096/Screenshot_2026-05-04_020409.png?ex=69f92975&is=69f7d7f5&hm=753a4fac187ffb8dae02b59f65a22aa5eeb684014a0b1a2b80385bf9a8f551fa&)
![Chat 2](https://cdn.discordapp.com/attachments/956515329608151121/1500651209281900615/Screenshot_2026-05-04_020356.png?ex=69f935d9&is=69f7e459&hm=1dbdd8dc3eda1a6b3be7176ba6228ad189539f203dc6a7ccea4a9c83534c5705&)
![Chat 3](https://cdn.discordapp.com/attachments/956515329608151121/1500637905570365561/Screenshot_2026-05-04_020525.png?ex=69f92975&is=69f7d7f5&hm=06a397c009b27ac74a349609f0e4fec507d615740e8b4a1cfa530d1a10ce4706&)

<div dir="rtl" align="right">
ArWoW Chat هو أدون (Addon) للعبة World of Warcraft (نسخة 3.3.5a) يضبط لك الشات ويدعم الكتابة بالعربي بدون مشاكل. الأدون يشبك الحروف ويرتبها صح من اليمين لليسار عشان تطلع لك واضحة وممتازة كأنها رسمية.
</div>

ArWoW Chat is a World of Warcraft (3.3.5a) addon designed to seamlessly enable Arabic text support in the game's chat system. It correctly handles Right-to-Left (RTL) text shaping, connects Arabic letters properly, and displays them beautifully.

<div dir="rtl" align="right">

## أهم المميزات
- **دعم الكتابة وربط الحروف (RTL):** يضبط لك النص تلقائياً داخل نوافذ الشات، فقاعات الكلام فوق الشخصيات (Chat Bubbles)، ومربع الكتابة.
- **ما يحوس اللغات الثانية:** الأدون يتجاهل النصوص الأجنبية عشان يضمن إن اللغات الثانية مثل الإسبانية والفرنسية والتشيكية تطلع بشكلها الصحيح وتشتغل تمام.
- **متوافق مع إضافات ثانية (Addons):** يشتغل معاك مثل الحلاوة ومندمج جاهز مع أشهر إضافات الواجهة والشات، مثل:
  - ElvUI
  - Prat-3.0
  - Chatter
  - DragonUI
  - Leatrix Plus
  - WIM (WoW Instant Messenger)
  - BasicChatMods (BCM)

## مشاكل معروفة (كلاينت 3.3.5a)
بسبب حدود الكلاينت (3.3.5a) القديم، فيه كم حاجة للحين:
- **نسخ النص العربي:** إذا نسخت محادثة عربية من اللعبة ولصقتها في ديسكورد أو أي برنامج محادثة ثانية، النص ممكن يطلع ملخبط أو معكوس.
- **تحديد النص بالماوس:** التظليل أو تحديد الكلام بالماوس في مربع الكتابة ما راح يكون دقيق.
- **التعديل وسط الكلمة:** الكليك بالماوس في نص الكلمة العربية عشان تعدلها ما راح يحط المؤشر في المكان الصح (الأفضل تستخدم أسهم الكيبورد أو تمسح الكلمة).

</div>

## Features
- **Native Arabic Shaping & RTL:** Automatically shapes text in chat frames, chat bubbles, and the chat edit input box.
- **European Language Friendly:** Skips shaping non-Arabic text to prevent mangling of other languages (e.g., Spanish, French, Czech).
- **Extensive Addon Compatibility:** Natively integrates with custom UI and chat addons out of the box, including:
  - ElvUI
  - Prat-3.0
  - Chatter
  - DragonUI
  - Leatrix Plus
  - WIM (WoW Instant Messenger)
  - BasicChatMods (BCM)

## Known Issues & Limitations
Due to the technical limitations of the 3.3.5a game client, the following issues are known:
- **Copying arabic text:** Copying an Arabic chat from the game and pasting it into Discord or any other chat may result in a reversed or garbled output.
- **Mouse Selection:** Highlighting or selecting text with the mouse within the chat edit box does not behave accurately for RTL shaped text.
- **Cursor Placement:** Clicking the mouse in the middle of an Arabic word in the text box to edit it will not place the cursor precisely (it is highly recommended to use the keyboard arrow keys instead).

## Credits & Acknowledgements
A massive thanks and full credits go to the authors of the **Arabic_Reshaper** logic, which provided the foundational Lua engine required to decode and shape the Arabic characters in this client:
- **[platine1](https://www.curseforge.com/members/platine1)**
- **[dragonarab](https://www.curseforge.com/members/dragonarab)**

Without their pioneering work on Arabic text rendering in the WoW client, this addon would not have been possible.

## License

MIT License

Copyright (c) 2026 Majed

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.

*(Note: The `Arabic_Reshaper.lua` file is credited to its respective original authors as linked above, and retains any of their original distribution rights.)*