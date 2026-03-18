import '../models/app_models.dart';

class ExerciseCatalog {
  static final Map<PainArea, Map<PainLevel, ExerciseProgram>> _programs = {
    PainArea.neckShoulders: {
      PainLevel.high: ExerciseProgram(
        id: 'neck-high',
        title: 'โปรแกรมคอ บ่า ไหล่ แบบเร่งด่วน',
        subtitle: 'ลดอาการตึงมากและช่วยรีเซ็ตท่านั่งระหว่างวัน',
        painArea: PainArea.neckShoulders,
        painLevel: PainLevel.high,
        reminderIntervalMinutes: 30,
        exercises: const [
          Exercise(
            id: 'chin-tuck',
            name: 'กดคางชิดอก',
            description:
                'นั่งหลังตรง ดึงคางเข้าหาลำคอ ค้างไว้ให้รู้สึกตึงเบา ๆ',
            reason: 'ช่วยลดคอพุ่งและแรงกดจากการจ้องจอนาน',
            durationSeconds: 30,
          ),
          Exercise(
            id: 'upper-trap-stretch',
            name: 'ยืดกล้ามเนื้อบ่า',
            description:
                'เอียงศีรษะไปด้านข้าง ใช้มือช่วยกดเบา ๆ แล้วสลับอีกข้าง',
            reason: 'คลายบ่าที่เกร็งจากการพิมพ์งานหรือยกไหล่ค้าง',
            durationSeconds: 40,
          ),
          Exercise(
            id: 'posterior-neck-stretch',
            name: 'ยืดคอด้านหลังเฉียง',
            description: 'ก้มหน้าเล็กน้อย หมุนศีรษะเฉียงประมาณ 45 องศาแล้วค้าง',
            reason: 'ลดความตึงลึกบริเวณท้ายทอยและคอด้านหลัง',
            durationSeconds: 40,
          ),
        ],
      ),
      PainLevel.medium: ExerciseProgram(
        id: 'neck-medium',
        title: 'โปรแกรมคอ บ่า ไหล่ แบบสมดุล',
        subtitle: 'คลายตึงและเพิ่มการไหลเวียนระหว่างทำงาน',
        painArea: PainArea.neckShoulders,
        painLevel: PainLevel.medium,
        reminderIntervalMinutes: 45,
        exercises: const [
          Exercise(
            id: 'neck-side-stretch',
            name: 'ยืดคอด้านข้าง',
            description: 'เอียงศีรษะไปด้านข้างแล้วกดเบา ๆ ค้างทีละข้าง',
            reason: 'ยืดกล้ามเนื้อคอที่เกร็งจากการนั่งค้างท่าเดิม',
            durationSeconds: 35,
          ),
          Exercise(
            id: 'shoulder-shrug',
            name: 'ยักไหล่ขึ้นลง',
            description:
                'ยกไหล่ขึ้น ค้างสั้น ๆ แล้วปล่อยลง ทำช้า ๆ อย่างต่อเนื่อง',
            reason: 'ช่วยให้บ่าและหัวไหล่คลายตัวเร็วขึ้น',
            durationSeconds: 30,
          ),
        ],
      ),
      PainLevel.low: ExerciseProgram(
        id: 'neck-low',
        title: 'โปรแกรมเปิดอกและป้องกันไหล่ห่อ',
        subtitle: 'เหมาะกับช่วงเริ่มล้าและต้องการป้องกันอาการสะสม',
        painArea: PainArea.neckShoulders,
        painLevel: PainLevel.low,
        reminderIntervalMinutes: 60,
        exercises: const [
          Exercise(
            id: 'prayer-pose-back',
            name: 'พนมมือไพล่หลัง',
            description:
                'พนมมือด้านหลัง กดฝ่ามือเข้าหากันและยกขึ้นเท่าที่ทำได้',
            reason: 'ช่วยเปิดอกและลดภาวะไหล่ห่อจากการนั่งนาน',
            durationSeconds: 30,
          ),
          Exercise(
            id: 'doorway-chest-stretch',
            name: 'ยืดอกที่ขอบประตู',
            description: 'ยืนพิงขอบประตู วางแขนและโน้มตัวไปข้างหน้าเบา ๆ',
            reason: 'ยืดอกที่หดสั้นจากการนั่งหน้าคอมต่อเนื่อง',
            durationSeconds: 40,
            requiresStanding: true,
          ),
          Exercise(
            id: 'arm-circles',
            name: 'หมุนแขนและหัวไหล่',
            description: 'กางแขนระดับไหล่ หมุนวงเล็กไปด้านหน้าและด้านหลัง',
            reason: 'กระตุ้นข้อต่อหัวไหล่ให้เคลื่อนไหวมากขึ้น',
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
        subtitle: 'สำหรับอาการตึงระหว่างสะบักและหลังงุ้มชัดเจน',
        painArea: PainArea.upperBack,
        painLevel: PainLevel.high,
        reminderIntervalMinutes: 30,
        exercises: const [
          Exercise(
            id: 'scapular-squeeze',
            name: 'บีบสะบักเข้าหากัน',
            description: 'นั่งตัวตรง ดึงสะบักเข้าหากัน ค้างเล็กน้อยแล้วคลาย',
            reason: 'ช่วยดึงหลังบนกลับมารับภาระแทนคอและบ่า',
            durationSeconds: 30,
          ),
          Exercise(
            id: 'elbow-pull-back',
            name: 'ดึงศอกไปด้านหลัง',
            description: 'งอศอก 90 องศา แล้วดึงศอกถอยหลังอย่างช้า ๆ',
            reason: 'เปิดอกและกระตุ้นกล้ามเนื้อหลังบนให้ทำงาน',
            durationSeconds: 30,
          ),
        ],
      ),
      PainLevel.medium: ExerciseProgram(
        id: 'upper-back-medium',
        title: 'โปรแกรมหลังบนยืดคลาย',
        subtitle: 'เพิ่มความยืดหยุ่นและลดความเมื่อยจากการนั่งค่อม',
        painArea: PainArea.upperBack,
        painLevel: PainLevel.medium,
        reminderIntervalMinutes: 45,
        exercises: const [
          Exercise(
            id: 'chair-cat-cow',
            name: 'แอ่นและโก่งหลังบนเก้าอี้',
            description: 'สลับแอ่นอกและโก่งหลังช้า ๆ ตามจังหวะลมหายใจ',
            reason: 'ช่วยให้กระดูกสันหลังส่วนอกเคลื่อนไหวมากขึ้น',
            durationSeconds: 35,
          ),
          Exercise(
            id: 'forward-stretch',
            name: 'ประสานมือดันไปข้างหน้า',
            description: 'ประสานมือ ดันฝ่ามือออกไปด้านหน้าแล้วค้าง',
            reason: 'ยืดจุดตึงบริเวณระหว่างสะบักได้ตรงจุด',
            durationSeconds: 35,
          ),
          Exercise(
            id: 'seated-trunk-twist',
            name: 'บิดลำตัวบนเก้าอี้',
            description: 'บิดตัวไปด้านข้างอย่างช้า ๆ ค้าง แล้วสลับอีกด้าน',
            reason: 'ลดความแข็งตึงของลำตัวส่วนอกและเอวบน',
            durationSeconds: 40,
          ),
        ],
      ),
      PainLevel.low: ExerciseProgram(
        id: 'upper-back-low',
        title: 'โปรแกรมป้องกันหลังบนล้า',
        subtitle: 'เหมาะกับคนที่เริ่มเมื่อยง่ายแต่อาการยังไม่หนัก',
        painArea: PainArea.upperBack,
        painLevel: PainLevel.low,
        reminderIntervalMinutes: 60,
        exercises: const [
          Exercise(
            id: 'overhead-reach',
            name: 'ยืดแขนเหนือศีรษะ',
            description: 'ยกแขนเหนือศีรษะแล้วดันลำตัวให้ยาวขึ้นเบา ๆ',
            reason: 'รีเซ็ตแนวลำตัวและลดแรงกดจากการนั่งนาน',
            durationSeconds: 30,
          ),
        ],
      ),
    },
    PainArea.lowerBack: {
      PainLevel.high: ExerciseProgram(
        id: 'lower-back-high',
        title: 'โปรแกรมเอวและหลังล่าง แบบเร่งด่วน',
        subtitle: 'สำหรับอาการเอวตึงมากจากการนั่งต่อเนื่อง',
        painArea: PainArea.lowerBack,
        painLevel: PainLevel.high,
        reminderIntervalMinutes: 30,
        exercises: const [
          Exercise(
            id: 'standing-back-extension',
            name: 'ยืนแอ่นหลัง',
            description: 'ลุกขึ้นยืน วางมือที่เอว แล้วแอ่นหลังเล็กน้อย',
            reason: 'ช่วยต้านท่านั่งงอหลังและลดแรงกดบริเวณหลังล่าง',
            durationSeconds: 25,
            requiresStanding: true,
          ),
          Exercise(
            id: 'single-knee-to-chest',
            name: 'ดึงเข่าชิดอกทีละข้าง',
            description: 'ยกเข่าขึ้นทีละข้าง ดึงเข้าหาลำตัวเท่าที่สบาย',
            reason: 'ลดแรงตึงรอบเอวและสะโพกที่ดึงรั้งหลังล่าง',
            durationSeconds: 40,
            requiresStanding: true,
          ),
        ],
      ),
      PainLevel.medium: ExerciseProgram(
        id: 'lower-back-medium',
        title: 'โปรแกรมเอวคลายตึงระหว่างวัน',
        subtitle: 'ลดหลังล่างแข็งและแรงดึงจากสะโพก',
        painArea: PainArea.lowerBack,
        painLevel: PainLevel.medium,
        reminderIntervalMinutes: 45,
        exercises: const [
          Exercise(
            id: 'seated-back-extension',
            name: 'แอ่นหลังบนเก้าอี้',
            description: 'นั่งเต็มสะโพกแล้วแอ่นอกขึ้นเบา ๆ ค้างสั้น ๆ',
            reason: 'คืนแนวโค้งตามธรรมชาติของหลังส่วนล่าง',
            durationSeconds: 30,
          ),
          Exercise(
            id: 'piriformis-stretch',
            name: 'ยืดสะโพกบนเก้าอี้',
            description:
                'วางข้อเท้าบนเข่าอีกข้าง แล้วโน้มตัวไปด้านหน้าเล็กน้อย',
            reason: 'คลายสะโพกที่มักดึงรั้งหลังล่างระหว่างวัน',
            durationSeconds: 40,
          ),
          Exercise(
            id: 'hamstring-stretch',
            name: 'ยืดต้นขาด้านหลัง',
            description: 'เหยียดขาไปด้านหน้าแล้วโน้มตัวตามเท่าที่สบาย',
            reason: 'ลดแรงดึงจากต้นขาหลังที่ส่งผลถึงเอว',
            durationSeconds: 40,
          ),
        ],
      ),
      PainLevel.low: ExerciseProgram(
        id: 'lower-back-low',
        title: 'โปรแกรมป้องกันเอวล้า',
        subtitle: 'เหมาะกับช่วงเริ่มเมื่อยจากการนั่งนาน',
        painArea: PainArea.lowerBack,
        painLevel: PainLevel.low,
        reminderIntervalMinutes: 60,
        exercises: const [
          Exercise(
            id: 'lower-back-trunk-twist',
            name: 'บิดลำตัวเบา ๆ บนเก้าอี้',
            description: 'บิดลำตัวไปด้านข้าง ค้างสั้น ๆ แล้วสลับอีกด้าน',
            reason: 'ลดความแข็งตึงจากการนั่งนิ่งต่อเนื่องเป็นเวลานาน',
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
      title: 'จัดโต๊ะให้หน้าจออยู่ระดับสายตา',
      summary:
          'การจัดอุปกรณ์ให้เหมาะช่วยลดคอพุ่ง ไหล่ห่อ และแรงกดสะสมจากการนั่งทำงานหน้าจอทั้งวัน',
      bullets: [
        'ขอบบนของหน้าจอควรอยู่ใกล้ระดับสายตา',
        'วางคีย์บอร์ดให้ศอกงอใกล้ 90 องศาและไหล่ไม่ยกค้าง',
        'ใช้พนักพิงรองหลังเพื่อลดการนั่งค่อม',
      ],
    ),
    TipArticle(
      title: 'พักสั้นแต่สม่ำเสมอ ดีกว่ารอให้ปวดมาก',
      summary:
          'การลุกเปลี่ยนอิริยาบถเป็นช่วงสั้น ๆ ช่วยลดความล้าสะสมและทำให้กล้ามเนื้อไม่ค้างท่าเดิมนานเกินไป',
      bullets: [
        'อาการมากเริ่มที่ทุก 30 นาที',
        'อาการปานกลางเริ่มที่ทุก 45 นาที',
        'เน้นป้องกันหรืออาการน้อยเริ่มที่ทุก 60 นาที',
      ],
    ),
    TipArticle(
      title: 'ยืดพร้อมปรับท่านั่งจะได้ผลดีกว่า',
      summary:
          'ท่าบริหารช่วยบรรเทาอาการได้ แต่ควรทำคู่กับการปรับโต๊ะ เก้าอี้ และพฤติกรรมการนั่งในแต่ละวัน',
      bullets: [
        'สลับยืน เดิน หรือเปลี่ยนท่านั่งทุกช่วงเวลาที่ทำได้',
        'หลีกเลี่ยงการยกไหล่เกร็งค้างระหว่างใช้เมาส์',
        'พักมือจากคีย์บอร์ดเมื่ออ่านหรือประชุม',
      ],
    ),
    TipArticle(
      title: 'หากมีอาการร้าว ชา หรือเวียนหัว ควรหยุดทันที',
      summary:
          'แอปนี้ใช้เพื่อดูแลตนเองเบื้องต้น ไม่ใช่เครื่องมือวินิจฉัยทางการแพทย์',
      bullets: [
        'หยุดทำท่าทันทีเมื่อเจ็บแปลบ ร้าวลงแขนขา หรือเวียนหัว',
        'หากอาการไม่ดีขึ้นควรพบแพทย์หรือนักกายภาพบำบัด',
        'ผู้ที่มีโรคประจำตัวเกี่ยวกับกระดูกและข้อควรขอคำแนะนำก่อนเริ่ม',
      ],
    ),
  ];
}
