import '../models/app_models.dart';

class ExerciseCatalog {
  static final Map<PainArea, Map<PainLevel, ExerciseProgram>> _programs = {
    PainArea.neckShoulders: {
      PainLevel.high: ExerciseProgram(
        id: 'neck-high',
        title: 'โปรแกรมคอ บ่า ไหล่ แบบเร่งด่วน',
        subtitle: 'สำหรับอาการตึงมากและควรพักถี่ขึ้น',
        painArea: PainArea.neckShoulders,
        painLevel: PainLevel.high,
        reminderIntervalMinutes: 30,
        exercises: const [
          Exercise(
            id: 'chin-tuck',
            name: 'กดคางชิดอก',
            description:
                'นั่งหลังตรง ดึงคางเข้าหาลำคอให้รู้สึกตึงด้านหลังคอ ค้างประมาณ 5-10 วินาที',
            reason: 'ช่วยแก้คอพุ่งและลดแรงกดจากการจ้องจอนาน',
            durationSeconds: 30,
          ),
          Exercise(
            id: 'upper-trap-stretch',
            name: 'ยืดกล้ามเนื้อบ่า',
            description:
                'มือหนึ่งไพล่หลัง เอียงศีรษะไปด้านตรงข้าม แล้วใช้มือช่วยกดเบา ๆ',
            reason: 'ลด trigger point ที่มักทำให้ปวดบ่าและไหล่เฉียบพลัน',
            durationSeconds: 40,
          ),
          Exercise(
            id: 'posterior-neck-stretch',
            name: 'ยืดคอด้านหลังเฉียง',
            description: 'ก้มหน้าเล็กน้อย หันศีรษะประมาณ 45 องศา แล้วกดลงเบา ๆ',
            reason: 'เหมาะกับอาการตึงลึกบริเวณท้ายทอยและแนวสะบักบน',
            durationSeconds: 40,
          ),
        ],
      ),
      PainLevel.medium: ExerciseProgram(
        id: 'neck-medium',
        title: 'โปรแกรมคอ บ่า ไหล่ สมดุล',
        subtitle: 'ลดอาการตึงและเพิ่มการไหลเวียนระหว่างวัน',
        painArea: PainArea.neckShoulders,
        painLevel: PainLevel.medium,
        reminderIntervalMinutes: 45,
        exercises: const [
          Exercise(
            id: 'neck-side-stretch',
            name: 'ยืดคอด้านข้าง',
            description: 'เอียงศีรษะไปด้านข้าง ใช้มือช่วยกดเบา ๆ ค้างทีละข้าง',
            reason: 'ยืดกล้ามเนื้อที่เกร็งจากการนั่งและพิมพ์งานต่อเนื่อง',
            durationSeconds: 35,
          ),
          Exercise(
            id: 'shoulder-shrug',
            name: 'ยักไหล่ขึ้นลง',
            description: 'ยกไหล่ขึ้นสูง ค้างสั้น ๆ แล้วผ่อนลง ทำซ้ำอย่างช้า ๆ',
            reason: 'เพิ่มการไหลเวียนเลือดและลดความล้าบริเวณบ่า',
            durationSeconds: 30,
          ),
        ],
      ),
      PainLevel.low: ExerciseProgram(
        id: 'neck-low',
        title: 'โปรแกรมเปิดอกและป้องกันไหล่ห่อ',
        subtitle: 'ใช้ป้องกันอาการก่อนเริ่มตึงจริง',
        painArea: PainArea.neckShoulders,
        painLevel: PainLevel.low,
        reminderIntervalMinutes: 60,
        exercises: const [
          Exercise(
            id: 'prayer-pose-back',
            name: 'พนมมือไพล่หลัง',
            description:
                'พนมมือด้านหลัง กดฝ่ามือเข้าหากันและยกขึ้นเท่าที่ทำได้อย่างสบาย',
            reason: 'ช่วยเปิดหน้าอกและลดภาวะไหล่ห่อ',
            durationSeconds: 30,
          ),
          Exercise(
            id: 'doorway-chest-stretch',
            name: 'ยืดอกที่ขอบประตู',
            description: 'ยืนที่ขอบประตู วางแขนแล้วโน้มตัวไปข้างหน้าเบา ๆ',
            reason: 'ยืดกล้ามเนื้ออกที่หดสั้นจากการนั่งจ้องจอ',
            durationSeconds: 40,
            requiresStanding: true,
          ),
          Exercise(
            id: 'arm-circles',
            name: 'หมุนแขนและหัวไหล่',
            description: 'กางแขนระดับไหล่ หมุนวงเล็กไปข้างหน้าและย้อนกลับ',
            reason: 'กระตุ้นข้อต่อหัวไหล่ให้ไม่ติดแข็ง',
            durationSeconds: 35,
            requiresStanding: true,
          ),
        ],
      ),
    },
    PainArea.upperBack: {
      PainLevel.high: ExerciseProgram(
        id: 'upper-back-high',
        title: 'โปรแกรมสะบักและหลังบน แบบเร่งด่วน',
        subtitle: 'เหมาะกับอาการหลังงุ้มและตึงระหว่างสะบักชัดเจน',
        painArea: PainArea.upperBack,
        painLevel: PainLevel.high,
        reminderIntervalMinutes: 30,
        exercises: const [
          Exercise(
            id: 'scapular-squeeze',
            name: 'บีบสะบักเข้าหากัน',
            description: 'นั่งตัวตรง ดึงสะบักเข้าหากัน ค้างแล้วคลายอย่างช้า ๆ',
            reason: 'ช่วยแก้ต้นเหตุจากหลังงุ้มและสะบักอ่อนแรง',
            durationSeconds: 30,
          ),
          Exercise(
            id: 'elbow-pull-back',
            name: 'ดึงศอกไปด้านหลัง',
            description: 'งอศอก 90 องศา ดึงศอกถอยหลังจนรู้สึกเกร็งหลังบน',
            reason: 'กระตุ้นกล้ามเนื้อหลังบนให้รับภาระแทนคอและบ่า',
            durationSeconds: 30,
          ),
        ],
      ),
      PainLevel.medium: ExerciseProgram(
        id: 'upper-back-medium',
        title: 'โปรแกรมหลังบนยืดคลาย',
        subtitle: 'เพิ่มความยืดหยุ่นและแก้หลังตึงจากการนั่งนาน',
        painArea: PainArea.upperBack,
        painLevel: PainLevel.medium,
        reminderIntervalMinutes: 45,
        exercises: const [
          Exercise(
            id: 'chair-cat-cow',
            name: 'แอ่นและโก่งหลังบนเก้าอี้',
            description: 'สลับแอ่นอกและโก่งหลังอย่างช้า ๆ ตามลมหายใจ',
            reason: 'ช่วยให้กระดูกสันหลังส่วนอกเคลื่อนไหวมากขึ้น',
            durationSeconds: 35,
          ),
          Exercise(
            id: 'forward-stretch',
            name: 'ประสานมือดันไปข้างหน้า',
            description: 'ประสานมือแล้วดันฝ่ามือออกให้รู้สึกตึงระหว่างสะบัก',
            reason: 'ยืดจุดตึงจากท่าพิมพ์งานและนั่งหลังค่อม',
            durationSeconds: 35,
          ),
          Exercise(
            id: 'seated-trunk-twist',
            name: 'บิดลำตัวบนเก้าอี้',
            description: 'บิดตัวไปด้านข้างช้า ๆ ค้าง แล้วสลับอีกด้าน',
            reason: 'เพิ่มการหมุนของลำตัวส่วนอกและลดความแข็งทื่อ',
            durationSeconds: 40,
          ),
        ],
      ),
      PainLevel.low: ExerciseProgram(
        id: 'upper-back-low',
        title: 'โปรแกรมป้องกันหลังบน',
        subtitle: 'เหมาะกับคนเริ่มเมื่อยง่ายแต่อยากป้องกันก่อนปวดสะสม',
        painArea: PainArea.upperBack,
        painLevel: PainLevel.low,
        reminderIntervalMinutes: 60,
        exercises: const [
          Exercise(
            id: 'overhead-reach',
            name: 'ยืดแขนเหนือศีรษะ',
            description: 'ยกแขนเหนือศีรษะแล้วดันตัวสูงขึ้นเบา ๆ',
            reason: 'ดึงแนวกระดูกสันหลังให้ยาวขึ้นและลดการกดทับจากการนั่ง',
            durationSeconds: 30,
          ),
        ],
      ),
    },
    PainArea.lowerBack: {
      PainLevel.high: ExerciseProgram(
        id: 'lower-back-high',
        title: 'โปรแกรมเอวและหลังล่าง แบบเร่งด่วน',
        subtitle: 'เหมาะกับอาการตึงเอวมากจากการนั่งต่อเนื่องนาน',
        painArea: PainArea.lowerBack,
        painLevel: PainLevel.high,
        reminderIntervalMinutes: 30,
        exercises: const [
          Exercise(
            id: 'standing-back-extension',
            name: 'ยืนแอ่นหลัง',
            description: 'ลุกขึ้นยืน วางมือที่เอว แอ่นหลังไปด้านหลังเล็กน้อย',
            reason: 'ช่วยต้านท่านั่งงอหลังและลดการกดบริเวณหลังล่าง',
            durationSeconds: 25,
            requiresStanding: true,
          ),
          Exercise(
            id: 'single-knee-to-chest',
            name: 'ดึงเข่าชิดอกทีละข้าง',
            description: 'ดึงเข่าเข้าหาลำตัวทีละข้างเท่าที่สบาย',
            reason: 'ลดแรงตึงรอบเอวและสะโพกที่ส่งผลต่อหลังล่าง',
            durationSeconds: 40,
            requiresStanding: true,
          ),
        ],
      ),
      PainLevel.medium: ExerciseProgram(
        id: 'lower-back-medium',
        title: 'โปรแกรมเอวคลายตึงระหว่างวัน',
        subtitle: 'แก้หลังล่างแข็งและลดแรงดึงที่สะโพก',
        painArea: PainArea.lowerBack,
        painLevel: PainLevel.medium,
        reminderIntervalMinutes: 45,
        exercises: const [
          Exercise(
            id: 'seated-back-extension',
            name: 'แอ่นหลังบนเก้าอี้',
            description: 'นั่งเต็มสะโพกแล้วแอ่นอกขึ้นเบา ๆ ค้างสั้น ๆ',
            reason: 'คืนความโค้งตามธรรมชาติของหลังส่วนล่าง',
            durationSeconds: 30,
          ),
          Exercise(
            id: 'piriformis-stretch',
            name: 'ยืดสะโพกบนเก้าอี้',
            description:
                'วางข้อเท้าบนเข่าอีกข้าง แล้วโน้มตัวไปด้านหน้าเล็กน้อย',
            reason: 'ลดแรงตึงจากสะโพกที่อาจดึงรั้งหลังล่าง',
            durationSeconds: 40,
          ),
          Exercise(
            id: 'hamstring-stretch',
            name: 'ยืดต้นขาด้านหลัง',
            description: 'เหยียดขาไปด้านหน้า โน้มตัวตามได้เท่าที่สบาย',
            reason: 'ลดแรงดึงที่เชิงกรานซึ่งส่งผลต่ออาการปวดเอว',
            durationSeconds: 40,
          ),
        ],
      ),
      PainLevel.low: ExerciseProgram(
        id: 'lower-back-low',
        title: 'โปรแกรมป้องกันเอวล้า',
        subtitle: 'เหมาะกับคนเริ่มเมื่อยจากนั่งนานแต่ยังไม่ปวดมาก',
        painArea: PainArea.lowerBack,
        painLevel: PainLevel.low,
        reminderIntervalMinutes: 60,
        exercises: const [
          Exercise(
            id: 'lower-back-trunk-twist',
            name: 'บิดลำตัวเบา ๆ บนเก้าอี้',
            description: 'บิดลำตัวไปด้านข้าง ค้างสั้น ๆ แล้วสลับอีกข้าง',
            reason: 'ลดอาการแข็งทื่อจากการนั่งนิ่งเป็นเวลานาน',
            durationSeconds: 35,
          ),
        ],
      ),
    },
  };

  static ExerciseProgram recommend(UserProfile profile) {
    return _programs[profile.painArea]![profile.painLevel]!;
  }

  static Map<PainArea, List<ExerciseProgram>> get programsByArea {
    return {
      for (final area in PainArea.values)
        area: _programs[area]!.values.toList(growable: false),
    };
  }

  static List<TipArticle> get tips => const [
    TipArticle(
      title: 'จัดโต๊ะให้จออยู่ระดับสายตา',
      summary:
          'งานวิจัยที่คุณให้มาชี้ว่าการจัดสภาพแวดล้อมการทำงานให้เหมาะสมช่วยลดอาการคอ บ่า ไหล่ และหลังได้ชัดเจน',
      bullets: [
        'ขอบบนของจอควรอยู่ใกล้ระดับสายตา',
        'วางคีย์บอร์ดให้ไหล่ผ่อนคลายและศอกงอใกล้ 90 องศา',
        'หนุนหลังให้เต็มพนักเก้าอี้เพื่อลดการงุ้ม',
      ],
    ),
    TipArticle(
      title: 'พักสั้นแต่สม่ำเสมอ ดีกว่ารอให้ปวดมาก',
      summary:
          'ผลจากแนวทางเตือนทุกช่วงเวลาแสดงว่าการหยุดพักระหว่างทำงานช่วยเพิ่มพฤติกรรมการลุกขยับและลดปวดสะสมได้',
      bullets: [
        'อาการมากใช้รอบเตือนทุก 30 นาที',
        'อาการปานกลางใช้ทุก 45 นาที',
        'เน้นป้องกันหรืออาการน้อยใช้ทุก 60 นาที',
      ],
    ),
    TipArticle(
      title: 'ยืดพร้อมปรับท่านั่งจะได้ผลดีกว่า',
      summary:
          'แอปควรสื่อว่าท่าบริหารเป็นส่วนหนึ่งของการดูแล ไม่ใช่แทนการจัดโต๊ะหรือปรับอิริยาบถทั้งหมด',
      bullets: [
        'สลับยืน เดิน หรือเปลี่ยนท่านั่งเป็นระยะ',
        'เลี่ยงการยกไหล่เกร็งตอนใช้เมาส์',
        'พักมือจากคีย์บอร์ดช่วงที่รับสายหรืออ่านข้อมูล',
      ],
    ),
    TipArticle(
      title: 'ถ้าเริ่มมีอาการร้าว ชา หรือเวียนหัว ให้หยุด',
      summary:
          'แอปนี้ควรใช้เป็นเครื่องมือดูแลตนเองเบื้องต้นเท่านั้น ไม่ใช่การวินิจฉัยอาการทางการแพทย์',
      bullets: [
        'หยุดทำทันทีเมื่อเจ็บแปลบหรือร้าวลงแขนขา',
        'ถ้าอาการไม่ดีขึ้นควรพบแพทย์หรือนักกายภาพบำบัด',
        'ผู้ที่มีโรคประจำตัวด้านกระดูกและข้อควรขอคำแนะนำก่อนเริ่มโปรแกรม',
      ],
    ),
  ];
}
