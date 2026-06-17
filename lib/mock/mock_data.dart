import '../models/service_model.dart';
import '../models/barber_model.dart';
import '../models/appointment_model.dart';
import '../models/user_model.dart';

class MockData {
  // ── Users ─────────────────────────────────────────────────────────────────
  static final List<Map<String, dynamic>> users = [
    {
      'id': 'u1',
      'name': 'Carlos Oliveira',
      'email': 'carlos@barberhub.com',
      'password': '123456',
      'role': UserRole.client,
    },
    {
      'id': 'u2',
      'name': 'Rafael Mendes',
      'email': 'rafael@barberhub.com',
      'password': '123456',
      'role': UserRole.barber,
      'barberId': 'b1',
    },
    {
      'id': 'u3',
      'name': 'Admin Hub',
      'email': 'admin@barberhub.com',
      'password': '123456',
      'role': UserRole.admin,
    },
    // ── Proprietários de Barbearia (novo perfil) — CORRIGIDO: ausente após conflito
    {
      'id': 'bs_owner_1',
      'name': 'Barbearia Clássica',
      'email': 'classica@barberhub.com',
      'password': '123456',
      'role': UserRole.barberShop,
      'linkedId': 'bs1',
    },
    {
      'id': 'bs_owner_2',
      'name': 'Studio Urbano',
      'email': 'studio@barberhub.com',
      'password': '123456',
      'role': UserRole.barberShop,
      'linkedId': 'bs2',
    },
    {
      'id': 'bs_owner_3',
      'name': 'Dom Navalha',
      'email': 'dom@barberhub.com',
      'password': '123456',
      'role': UserRole.barberShop,
      'linkedId': 'bs3',
    },
  ];

  // ── Barbershops ───────────────────────────────────────────────────────────
  static List<BarbershopModel> barbershops() {
    return [
      // ── 1. Barbearia Clássica ─────────────────────────────────────────────
      BarbershopModel(
        id: 'bs1',
        name: 'Barbearia Clássica',
        address: 'Rua das Flores, 123 – Centro',
        rating: 4.9,
        reviewCount: 348,
        coverEmoji: '✂️',
        description:
            'Tradição e elegância desde 2010. Ambiente sofisticado com atendimento personalizado para homens que valorizam estilo.',
        phone: '(11) 3456-7890',
        services: [
          ServiceModel(
              id: 'bs1_s1',
              name: 'Corte Clássico',
              description:
                  'Corte tradicional com tesoura e máquina. Inclui lavagem, corte personalizado e finalização com produtos premium.',
              price: 45.00,
              durationMinutes: 30,
              iconName: 'cut'),
          ServiceModel(
              id: 'bs1_s2',
              name: 'Barba Completa',
              description:
                  'Modelagem e aparação da barba com navalha e toalha quente. Inclui hidratação pós-barba.',
              price: 35.00,
              durationMinutes: 25,
              iconName: 'face'),
          ServiceModel(
              id: 'bs1_s3',
              name: 'Corte + Barba',
              description:
                  'Combo completo: corte de cabelo e barba na mesma sessão.',
              price: 70.00,
              durationMinutes: 50,
              iconName: 'combo'),
          ServiceModel(
              id: 'bs1_s4',
              name: 'Sobrancelha',
              description:
                  'Design e alinhamento das sobrancelhas com linha e pinça.',
              price: 20.00,
              durationMinutes: 15,
              iconName: 'brow'),
        ],
        barbers: [
          BarberModel(
              id: 'b1',
              name: 'Rafael Mendes',
              specialty: 'Cortes Clássicos & Fade',
              rating: 4.9,
              reviewCount: 238,
              avatarInitials: 'RM',
              phone: '(11) 99999-1111'),
          BarberModel(
              id: 'b2',
              name: 'Diego Costa',
              specialty: 'Barba & Navalha',
              rating: 4.8,
              reviewCount: 175,
              avatarInitials: 'DC',
              phone: '(11) 99999-2222'),
        ],
        products: [
          const ProductModel(
            id: 'bs1_p1',
            barbershopId: 'bs1',
            name: 'Pomada Modeladora Classic',
            description:
                'Pomada de fixação forte com brilho médio. Ideal para cortes clássicos e penteados tradicionais. Fragrância amadeirada suave.',
            price: 42.90,
            originalPrice: 54.90,
            category: ProductCategory.pomade,
            imageEmoji: '💈',
            brand: 'BarberPro',
            isFeatured: true,
            stockQty: 15,
          ),
          const ProductModel(
            id: 'bs1_p2',
            barbershopId: 'bs1',
            name: 'Óleo para Barba Premium',
            description:
                'Blend de óleos naturais para hidratar e amaciar a barba. Com argan, jojoba e vitamina E. Deixa a barba macia e brilhante.',
            price: 38.50,
            category: ProductCategory.beard,
            imageEmoji: '🧔',
            brand: 'BarberPro',
            isFeatured: true,
            stockQty: 22,
          ),
          const ProductModel(
            id: 'bs1_p3',
            barbershopId: 'bs1',
            name: 'Shampoo Antiqueda',
            description:
                'Shampoo com cafeína e biotina para fortalecer os fios e estimular o crescimento capilar. Uso diário.',
            price: 29.90,
            category: ProductCategory.shampoo,
            imageEmoji: '🧴',
            brand: 'HairCare',
            stockQty: 30,
          ),
          const ProductModel(
            id: 'bs1_p4',
            barbershopId: 'bs1',
            name: 'Kit Barba Completo',
            description:
                'Kit com óleo de barba, balm pós-barba e pente de madeira. Tudo que você precisa para manter a barba impecável.',
            price: 89.90,
            originalPrice: 109.90,
            category: ProductCategory.kit,
            imageEmoji: '🎁',
            brand: 'BarberPro',
            isFeatured: true,
            stockQty: 8,
          ),
          const ProductModel(
            id: 'bs1_p5',
            barbershopId: 'bs1',
            name: 'Balm Pós-Barba',
            description:
                'Balm calmante e hidratante para aplicar após o barbear. Reduz vermelhidão e irrita. Com aloe vera e manteiga de karité.',
            price: 32.00,
            category: ProductCategory.beard,
            imageEmoji: '🧔',
            brand: 'BarberPro',
            stockQty: 18,
          ),
        ],
      ),

      // ── 2. Studio Urbano ──────────────────────────────────────────────────
      BarbershopModel(
        id: 'bs2',
        name: 'Studio Urbano',
        address: 'Av. Paulista, 900 – Bela Vista',
        rating: 4.7,
        reviewCount: 212,
        coverEmoji: '🪒',
        description:
            'Estilo contemporâneo com técnicas modernas. Especialistas em degradê e coloração masculina.',
        phone: '(11) 2345-6789',
        services: [
          ServiceModel(
              id: 'bs2_s1',
              name: 'Degradê Americano',
              description: 'Fade perfeito com máquina e acabamento impecável.',
              price: 55.00,
              durationMinutes: 35,
              iconName: 'cut'),
          ServiceModel(
              id: 'bs2_s2',
              name: 'Platinado / Coloração',
              description:
                  'Descoloração, mechas ou coloração completa com produtos profissionais.',
              price: 120.00,
              durationMinutes: 90,
              iconName: 'color'),
          ServiceModel(
              id: 'bs2_s3',
              name: 'Hidratação Capilar',
              description:
                  'Tratamento intensivo com máscara nutritiva, vitaminas e óleos essenciais.',
              price: 55.00,
              durationMinutes: 40,
              iconName: 'spa'),
          ServiceModel(
              id: 'bs2_s4',
              name: 'Corte Navalhado',
              description:
                  'Acabamento com navalha para um visual afiado e bem definido.',
              price: 65.00,
              durationMinutes: 45,
              iconName: 'cut'),
        ],
        barbers: [
          BarberModel(
              id: 'b3',
              name: 'Thiago Alves',
              specialty: 'Coloração & Química',
              rating: 4.7,
              reviewCount: 112,
              avatarInitials: 'TA',
              phone: '(11) 99999-3333'),
          BarberModel(
              id: 'b4',
              name: 'Lucas Ferreira',
              specialty: 'Cortes Modernos',
              rating: 4.6,
              reviewCount: 89,
              avatarInitials: 'LF',
              phone: '(11) 99999-4444'),
        ],
        products: [
          const ProductModel(
            id: 'bs2_p1',
            barbershopId: 'bs2',
            name: 'Tônico Capilar Urbano',
            description:
                'Tônico com niacinamida e zinco que controla a oleosidade, reduz caspa e fortalece o couro cabeludo. Resultado em 4 semanas.',
            price: 55.00,
            category: ProductCategory.shampoo,
            imageEmoji: '🧴',
            brand: 'UrbanStyle',
            isFeatured: true,
            stockQty: 12,
          ),
          const ProductModel(
            id: 'bs2_p2',
            barbershopId: 'bs2',
            name: 'Pomada Matte Efeito Opaco',
            description:
                'Pomada de alta fixação com efeito matte. Sem brilho, para o look moderno e despojado. Base aquosa de fácil remoção.',
            price: 48.00,
            originalPrice: 58.00,
            category: ProductCategory.pomade,
            imageEmoji: '💈',
            brand: 'UrbanStyle',
            isFeatured: true,
            stockQty: 20,
          ),
          const ProductModel(
            id: 'bs2_p3',
            barbershopId: 'bs2',
            name: 'Máscara de Hidratação Capilar',
            description:
                'Máscara intensiva com queratina hidrolisada e óleo de argan. Recupera cabelos danificados por química em um único tratamento.',
            price: 62.00,
            category: ProductCategory.shampoo,
            imageEmoji: '🧴',
            brand: 'HydraLab',
            stockQty: 10,
          ),
          const ProductModel(
            id: 'bs2_p4',
            barbershopId: 'bs2',
            name: 'Leave-in Protetor Térmico',
            description:
                'Protetor térmico em spray para uso antes do secador ou chapinha. Protege até 230°C e reduz o frizz.',
            price: 39.90,
            category: ProductCategory.shampoo,
            imageEmoji: '🧴',
            brand: 'UrbanStyle',
            stockQty: 25,
          ),
          const ProductModel(
            id: 'bs2_p5',
            barbershopId: 'bs2',
            name: 'Kit Coloração em Casa',
            description:
                'Kit completo para retocar raízes entre visitas ao salão. Inclui coloração, oxidante e luvas descartáveis.',
            price: 45.00,
            category: ProductCategory.kit,
            imageEmoji: '🎁',
            brand: 'ColorPro',
            isFeatured: false,
            stockQty: 6,
          ),
        ],
      ),

      // ── 3. Dom Navalha ────────────────────────────────────────────────────
      BarbershopModel(
        id: 'bs3',
        name: 'Dom Navalha',
        address: 'Rua Augusta, 450 – Consolação',
        rating: 4.8,
        reviewCount: 289,
        coverEmoji: '👑',
        description:
            'A arte da navalha elevada ao máximo. Experiência única com produtos importados e atendimento VIP.',
        phone: '(11) 3333-9999',
        services: [
          ServiceModel(
              id: 'bs3_s1',
              name: 'Barba VIP',
              description:
                  'Ritual completo de barba: toalha quente, óleo de barba importado, navalha e finalização.',
              price: 80.00,
              durationMinutes: 45,
              iconName: 'face'),
          ServiceModel(
              id: 'bs3_s2',
              name: 'Corte Premium',
              description:
                  'Corte personalizado com consultoria de estilo inclusa.',
              price: 75.00,
              durationMinutes: 50,
              iconName: 'cut'),
          ServiceModel(
              id: 'bs3_s3',
              name: 'Pacote Rei',
              description:
                  'Corte + Barba VIP + Hidratação. O combo mais completo da casa.',
              price: 150.00,
              durationMinutes: 110,
              iconName: 'combo'),
          ServiceModel(
              id: 'bs3_s4',
              name: 'Relaxamento Facial',
              description:
                  'Limpeza de pele e máscara facial hidratante pós-navalha.',
              price: 60.00,
              durationMinutes: 30,
              iconName: 'spa'),
        ],
        barbers: [
          BarberModel(
              id: 'b5',
              name: 'Marcelo Viana',
              specialty: 'Navalha & Rituais de Barba',
              rating: 4.9,
              reviewCount: 204,
              avatarInitials: 'MV',
              phone: '(11) 99888-5555'),
          BarberModel(
              id: 'b6',
              name: 'Fábio Reis',
              specialty: 'Cortes Premium',
              rating: 4.7,
              reviewCount: 145,
              avatarInitials: 'FR',
              phone: '(11) 99888-6666'),
        ],
        products: [
          const ProductModel(
            id: 'bs3_p1',
            barbershopId: 'bs3',
            name: 'Navalha Artesanal Dom',
            description:
                'Navalha de aço inoxidável forjado à mão. Cabo em madeira de lei com acabamento premium. Inclui estojo de couro.',
            price: 189.90,
            category: ProductCategory.tool,
            imageEmoji: '✂️',
            brand: 'Dom Artesanal',
            isFeatured: true,
            stockQty: 5,
          ),
          const ProductModel(
            id: 'bs3_p2',
            barbershopId: 'bs3',
            name: 'Óleo de Barba Importado',
            description:
                'Blend exclusivo com 12 óleos essenciais importados. Fragrância amadeirada com notas de sândalo e vetiver. 30ml.',
            price: 95.00,
            originalPrice: 120.00,
            category: ProductCategory.beard,
            imageEmoji: '🧔',
            brand: 'Dom Signature',
            isFeatured: true,
            stockQty: 14,
          ),
          const ProductModel(
            id: 'bs3_p3',
            barbershopId: 'bs3',
            name: 'Creme de Barbear Premium',
            description:
                'Creme de barbear com manteiga de karité e aloe vera. Proporciona deslize perfeito da navalha sem irritar.',
            price: 68.00,
            category: ProductCategory.beard,
            imageEmoji: '🧔',
            brand: 'Dom Signature',
            stockQty: 20,
          ),
          const ProductModel(
            id: 'bs3_p4',
            barbershopId: 'bs3',
            name: 'Pedra de Alúmen Natural',
            description:
                'Pedra de alúmen 100% natural para fechar poros e estancar cortes. Antibacteriana e antisséptica. 100g.',
            price: 24.90,
            category: ProductCategory.skincare,
            imageEmoji: '✨',
            brand: 'NaturalCare',
            stockQty: 40,
          ),
          const ProductModel(
            id: 'bs3_p5',
            barbershopId: 'bs3',
            name: 'Kit Dom VIP',
            description:
                'Kit exclusivo Dom Navalha: óleo de barba, creme de barbear, balm pós-barba e pedra de alúmen. Embalagem presente.',
            price: 249.90,
            originalPrice: 307.80,
            category: ProductCategory.kit,
            imageEmoji: '🎁',
            brand: 'Dom Signature',
            isFeatured: true,
            stockQty: 4,
          ),
          const ProductModel(
            id: 'bs3_p6',
            barbershopId: 'bs3',
            name: 'Hidratante Facial Masculino',
            description:
                'Hidratante leve com FPS 15, vitamina C e ácido hialurônico. Ideal para uso diário no rosto.',
            price: 72.00,
            category: ProductCategory.skincare,
            imageEmoji: '✨',
            brand: 'Dom Skincare',
            stockQty: 11,
          ),
        ],
      ),

      // ── 4. Barber Lab ──────────────────────────────────────────────────────
      BarbershopModel(
        id: 'bs4',
        name: 'Barber Lab',
        address: 'Rua Oscar Freire, 310 – Jardins',
        rating: 4.6,
        reviewCount: 156,
        coverEmoji: '🧪',
        description:
            'Laboratório de estilos modernos. Especializados em transições de cor, texturas e cortes exclusivos.',
        phone: '(11) 4567-1234',
        services: [
          ServiceModel(
              id: 'bs4_s1',
              name: 'Mechas Modernas',
              description:
                  'Mechas finas ou grossas com técnica de babylights para visual natural.',
              price: 140.00,
              durationMinutes: 100,
              iconName: 'color'),
          ServiceModel(
              id: 'bs4_s2',
              name: 'Tonalização',
              description:
                  'Cobertura de grisalhos ou mudança de tom com produtos semi-permanentes.',
              price: 85.00,
              durationMinutes: 60,
              iconName: 'color'),
          ServiceModel(
              id: 'bs4_s3',
              name: 'Corte Texturizado',
              description:
                  'Corte com navalha para criar volume e textura natural.',
              price: 60.00,
              durationMinutes: 40,
              iconName: 'cut'),
          ServiceModel(
              id: 'bs4_s4',
              name: 'Hidratação Profunda',
              description:
                  'Tratamento intensivo com queratina e vitaminas para cabelos danificados.',
              price: 90.00,
              durationMinutes: 60,
              iconName: 'spa'),
        ],
        barbers: [
          BarberModel(
              id: 'b7',
              name: 'Caio Drummond',
              specialty: 'Coloração & Mechas',
              rating: 4.8,
              reviewCount: 98,
              avatarInitials: 'CD',
              phone: '(11) 97777-7777'),
          BarberModel(
              id: 'b8',
              name: 'Natã Lima',
              specialty: 'Tratamentos Capilares',
              rating: 4.5,
              reviewCount: 73,
              avatarInitials: 'NL',
              phone: '(11) 97777-8888'),
        ],
        products: [
          const ProductModel(
            id: 'bs4_p1',
            barbershopId: 'bs4',
            name: 'Shampoo Matizador Silver',
            description:
                'Shampoo roxo matizador para neutralizar tons amarelos em cabelos loiros ou grisalhos. Uso semanal recomendado.',
            price: 49.90,
            category: ProductCategory.shampoo,
            imageEmoji: '🧴',
            brand: 'LabColor',
            isFeatured: true,
            stockQty: 18,
          ),
          const ProductModel(
            id: 'bs4_p2',
            barbershopId: 'bs4',
            name: 'Ampola de Reconstrução',
            description:
                'Ampola de tratamento intensivo com proteínas da seda e ceramidas. Recupera cabelos extremamente danificados em uma única aplicação.',
            price: 28.00,
            category: ProductCategory.shampoo,
            imageEmoji: '🧴',
            brand: 'LabTech',
            isFeatured: true,
            stockQty: 35,
          ),
          const ProductModel(
            id: 'bs4_p3',
            barbershopId: 'bs4',
            name: 'Pó Descolorante Profissional',
            description:
                'Pó para descoloração com baixo índice de amônia. Clareamento de até 8 tons com menor dano ao fio.',
            price: 35.00,
            originalPrice: 42.00,
            category: ProductCategory.shampoo,
            imageEmoji: '🧴',
            brand: 'LabColor',
            stockQty: 9,
          ),
          const ProductModel(
            id: 'bs4_p4',
            barbershopId: 'bs4',
            name: 'Sérum Anti-Frizz',
            description:
                'Sérum de silicone para controle do frizz e brilho intenso. Leve, não pesa nos fios. Aplicar em cabelos úmidos ou secos.',
            price: 44.90,
            category: ProductCategory.shampoo,
            imageEmoji: '🧴',
            brand: 'LabTech',
            stockQty: 22,
          ),
          const ProductModel(
            id: 'bs4_p5',
            barbershopId: 'bs4',
            name: 'Kit Manutenção Loiro',
            description:
                'Kit completo para loiros: shampoo matizador, condicionador nutritivo e ampola de reconstrução. 3 produtos essenciais.',
            price: 99.90,
            originalPrice: 127.80,
            category: ProductCategory.kit,
            imageEmoji: '🎁',
            brand: 'LabColor',
            isFeatured: true,
            stockQty: 7,
          ),
        ],
      ),

      // ── 5. Corte & Arte ───────────────────────────────────────────────────
      BarbershopModel(
        id: 'bs5',
        name: 'Corte & Arte',
        address: 'Av. Rebouças, 1500 – Pinheiros',
        rating: 4.5,
        reviewCount: 134,
        coverEmoji: '🎨',
        description:
            'Barbearia familiar com ambiente aconchegante. Atendimento para toda a família, do pai ao filho.',
        phone: '(11) 5678-4321',
        services: [
          ServiceModel(
              id: 'bs5_s1',
              name: 'Corte Infantil',
              description:
                  'Corte especial para crianças até 12 anos com paciência e carinho.',
              price: 30.00,
              durationMinutes: 25,
              iconName: 'cut'),
          ServiceModel(
              id: 'bs5_s2',
              name: 'Corte Masculino',
              description:
                  'Corte tradicional masculino com acabamento na máquina.',
              price: 40.00,
              durationMinutes: 30,
              iconName: 'cut'),
          ServiceModel(
              id: 'bs5_s3',
              name: 'Barba Simples',
              description:
                  'Aparação e alinhamento da barba com máquina e tesoura.',
              price: 25.00,
              durationMinutes: 20,
              iconName: 'face'),
          ServiceModel(
              id: 'bs5_s4',
              name: 'Combo Família',
              description:
                  'Corte masculino + corte infantil. Ideal para pai e filho.',
              price: 60.00,
              durationMinutes: 55,
              iconName: 'combo'),
        ],
        barbers: [
          BarberModel(
              id: 'b9',
              name: 'Eduardo Souza',
              specialty: 'Cortes Clássicos & Infantis',
              rating: 4.6,
              reviewCount: 117,
              avatarInitials: 'ES',
              phone: '(11) 96666-9999'),
          BarberModel(
              id: 'b10',
              name: 'Rodrigo Melo',
              specialty: 'Barba & Acabamento',
              rating: 4.4,
              reviewCount: 81,
              avatarInitials: 'RM',
              phone: '(11) 96666-0000'),
        ],
        products: [
          const ProductModel(
            id: 'bs5_p1',
            barbershopId: 'bs5',
            name: 'Pomada Kids Sem Química',
            description:
                'Pomada especial para crianças. Sem álcool, sem parabenos e sem sulfatos. Fixação leve, fácil de remover.',
            price: 24.90,
            category: ProductCategory.pomade,
            imageEmoji: '💈',
            brand: 'KidsCare',
            isFeatured: true,
            stockQty: 28,
          ),
          const ProductModel(
            id: 'bs5_p2',
            barbershopId: 'bs5',
            name: 'Shampoo Familiar 3 em 1',
            description:
                'Shampoo, condicionador e sabonete em um só produto. Para toda a família, incluindo crianças. Sem lágrimas.',
            price: 22.90,
            originalPrice: 29.90,
            category: ProductCategory.shampoo,
            imageEmoji: '🧴',
            brand: 'FamilyCare',
            isFeatured: true,
            stockQty: 45,
          ),
          const ProductModel(
            id: 'bs5_p3',
            barbershopId: 'bs5',
            name: 'Pente de Madeira Artesanal',
            description:
                'Pente de madeira de bambu para cabelos e barba. Antiestático, hipoalergênico. Disponível em tamanho médio.',
            price: 19.90,
            category: ProductCategory.tool,
            imageEmoji: '✂️',
            brand: 'NaturalArt',
            stockQty: 30,
          ),
          const ProductModel(
            id: 'bs5_p4',
            barbershopId: 'bs5',
            name: 'Gel Fixador Extra Forte',
            description:
                'Gel de fixação extra forte com efeito molhado. Ideal para penteados com muito volume e definição.',
            price: 18.90,
            category: ProductCategory.pomade,
            imageEmoji: '💈',
            brand: 'StyleFix',
            stockQty: 50,
          ),
          const ProductModel(
            id: 'bs5_p5',
            barbershopId: 'bs5',
            name: 'Kit Pai & Filho',
            description:
                'Kit especial com pomada kids, pomada adulto e shampoo familiar. O presente ideal para os dois.',
            price: 64.90,
            originalPrice: 79.70,
            category: ProductCategory.kit,
            imageEmoji: '🎁',
            brand: 'FamilyCare',
            isFeatured: true,
            stockQty: 10,
          ),
        ],
      ),
    ];
  }

  // ── Legacy helpers ────────────────────────────────────────────────────────
  static List<ServiceModel> services() => barbershops().first.services;
  static List<BarberModel> barbers() => barbershops().first.barbers;

  // ── Seed Appointments ─────────────────────────────────────────────────────
  static List<AppointmentModel> seedAppointments(List<BarbershopModel> shops) {
    final now = DateTime.now();
    final bs1 = shops[0];
    final bs2 = shops[1];
    final bs3 = shops[2];
    return [
      AppointmentModel(
          id: 'a1',
          clientId: 'u1',
          clientName: 'Carlos Oliveira',
          service: bs1.services[0],
          barber: bs1.barbers[0],
          barbershop: bs1,
          date: now.add(const Duration(days: 1)),
          timeSlot: '10:00'),
      AppointmentModel(
          id: 'a2',
          clientId: 'u1',
          clientName: 'Carlos Oliveira',
          service: bs2.services[0],
          barber: bs2.barbers[1],
          barbershop: bs2,
          date: now.add(const Duration(days: 5)),
          timeSlot: '14:30'),
      AppointmentModel(
          id: 'a3',
          clientId: 'u1',
          clientName: 'Carlos Oliveira',
          service: bs1.services[1],
          barber: bs1.barbers[0],
          barbershop: bs1,
          date: now.subtract(const Duration(days: 7)),
          timeSlot: '09:00',
          status: AppointmentStatus.completed),
      AppointmentModel(
          id: 'a4',
          clientId: 'ext1',
          clientName: 'Marcos Lima',
          service: bs1.services[0],
          barber: bs1.barbers[0],
          barbershop: bs1,
          date: now,
          timeSlot: '08:00'),
      AppointmentModel(
          id: 'a5',
          clientId: 'ext2',
          clientName: 'Pedro Santos',
          service: bs3.services[0],
          barber: bs3.barbers[0],
          barbershop: bs3,
          date: now,
          timeSlot: '11:00'),
      AppointmentModel(
          id: 'a6',
          clientId: 'ext3',
          clientName: 'João Ferreira',
          service: bs2.services[0],
          barber: bs2.barbers[0],
          barbershop: bs2,
          date: now.subtract(const Duration(days: 2)),
          timeSlot: '15:00',
          status: AppointmentStatus.completed),
      AppointmentModel(
          id: 'a7',
          clientId: 'ext4',
          clientName: 'André Costa',
          service: bs1.services[2],
          barber: bs1.barbers[1],
          barbershop: bs1,
          date: now.add(const Duration(days: 2)),
          timeSlot: '16:00'),
    ];
  }

  static const List<String> timeSlots = [
    '08:00',
    '08:30',
    '09:00',
    '09:30',
    '10:00',
    '10:30',
    '11:00',
    '11:30',
    '13:00',
    '13:30',
    '14:00',
    '14:30',
    '15:00',
    '15:30',
    '16:00',
    '16:30',
    '17:00',
    '17:30',
  ];

  // ── Seed Reviews ──────────────────────────────────────────────────────────
  // Cria avaliações mockadas para agendamentos já concluídos.
  // Também vincula cada ReviewModel ao AppointmentModel correspondente,
  // e recalcula rating/reviewCount das barbearias e barbeiros.
  static List<ReviewModel> seedReviews(List<AppointmentModel> appointments) {
    final now = DateTime.now();
    final reviews = <ReviewModel>[];

    // Helper: cria review e vincula ao appointment
    ReviewModel make({
      required String id,
      required AppointmentModel appt,
      required int rating,
      String? comment,
      int daysAgo = 1,
    }) {
      final r = ReviewModel(
        id: id,
        appointmentId: appt.id,
        clientId: appt.clientId,
        clientName: appt.clientName,
        barbershopId: appt.barbershop.id,
        barbershopName: appt.barbershop.name,
        barberId: appt.barber.id,
        barberName: appt.barber.name,
        serviceName: appt.service.name,
        barbershopRating: rating,
        barberRating: rating,
        comment: comment,
        createdAt: now.subtract(Duration(days: daysAgo)),
      );
      appt.review = r; // vincula ao agendamento
      return r;
    }

    // Busca agendamentos concluídos pelo id
    final completed =
        appointments.where((a) => a.status == AppointmentStatus.completed);

    for (final appt in completed) {
      switch (appt.id) {
        case 'a3':
          reviews.add(make(
            id: 'r1',
            appt: appt,
            rating: 5,
            comment:
                'Rafael é incrível! Corte perfeito, ambiente ótimo e atendimento nota 10. Já virei cliente fiel.',
            daysAgo: 7,
          ));
          break;
        case 'a6':
          reviews.add(make(
            id: 'r2',
            appt: appt,
            rating: 4,
            comment:
                'Bom atendimento e ambiente agradável. Degradê ficou muito bom, voltarei com certeza.',
            daysAgo: 2,
          ));
          break;
      }
    }

    // Reviews adicionais de outros clientes (enriquecem o histórico das barbearias)
    final shops = {for (final a in appointments) a.barbershop.id: a.barbershop};

    // bs1 — Barbearia Clássica
    if (shops.containsKey('bs1')) {
      final bs1 = shops['bs1']!;
      reviews.addAll([
        ReviewModel(
          id: 'r3',
          appointmentId: 'ext_a1',
          clientId: 'ext_c1',
          clientName: 'Felipe Rodrigues',
          barbershopId: 'bs1',
          barbershopName: bs1.name,
          barberId: 'b1',
          barberName: 'Rafael Mendes',
          serviceName: 'Corte Clássico',
          barbershopRating: 5,
          barberRating: 5,
          comment:
              'Melhor barbearia da cidade. Rafael sabe exatamente o que você quer.',
          createdAt: now.subtract(const Duration(days: 3)),
        ),
        ReviewModel(
          id: 'r4',
          appointmentId: 'ext_a2',
          clientId: 'ext_c2',
          clientName: 'Bruno Nascimento',
          barbershopId: 'bs1',
          barbershopName: bs1.name,
          barberId: 'b2',
          barberName: 'Diego Costa',
          serviceName: 'Barba Completa',
          barbershopRating: 5,
          barberRating: 5,
          comment: 'Diego é um artista com a navalha. Barba impecável!',
          createdAt: now.subtract(const Duration(days: 5)),
        ),
        ReviewModel(
          id: 'r5',
          appointmentId: 'ext_a3',
          clientId: 'ext_c3',
          clientName: 'Gustavo Almeida',
          barbershopId: 'bs1',
          barbershopName: bs1.name,
          barberId: 'b1',
          barberName: 'Rafael Mendes',
          serviceName: 'Corte + Barba',
          barbershopRating: 4,
          barberRating: 4,
          comment: 'Ótimo combo, preço justo e ambiente muito bacana.',
          createdAt: now.subtract(const Duration(days: 10)),
        ),
        ReviewModel(
          id: 'r6',
          appointmentId: 'ext_a4',
          clientId: 'ext_c4',
          clientName: 'Lucas Pereira',
          barbershopId: 'bs1',
          barbershopName: bs1.name,
          barberId: 'b2',
          barberName: 'Diego Costa',
          serviceName: 'Corte Clássico',
          barbershopRating: 5,
          barberRating: 5,
          comment: null,
          createdAt: now.subtract(const Duration(days: 14)),
        ),
      ]);
    }

    // bs2 — Studio Urbano
    if (shops.containsKey('bs2')) {
      final bs2 = shops['bs2']!;
      reviews.addAll([
        ReviewModel(
          id: 'r7',
          appointmentId: 'ext_b1',
          clientId: 'ext_c5',
          clientName: 'Matheus Lima',
          barbershopId: 'bs2',
          barbershopName: bs2.name,
          barberId: 'b3',
          barberName: 'Thiago Alves',
          serviceName: 'Degradê Americano',
          barbershopRating: 5,
          barberRating: 5,
          comment: 'Fade perfeito! Thiago é um especialista em degradê.',
          createdAt: now.subtract(const Duration(days: 4)),
        ),
        ReviewModel(
          id: 'r8',
          appointmentId: 'ext_b2',
          clientId: 'ext_c6',
          clientName: 'Rafael Costa',
          barbershopId: 'bs2',
          barbershopName: bs2.name,
          barberId: 'b4',
          barberName: 'Lucas Ferreira',
          serviceName: 'Corte Navalhado',
          barbershopRating: 4,
          barberRating: 4,
          comment: 'Muito bom! Apenas demorou um pouco mais que o esperado.',
          createdAt: now.subtract(const Duration(days: 8)),
        ),
        ReviewModel(
          id: 'r9',
          appointmentId: 'ext_b3',
          clientId: 'ext_c7',
          clientName: 'Diego Martins',
          barbershopId: 'bs2',
          barbershopName: bs2.name,
          barberId: 'b3',
          barberName: 'Thiago Alves',
          serviceName: 'Platinado / Coloração',
          barbershopRating: 5,
          barberRating: 5,
          comment:
              'Platinado ficou exatamente como eu queria. Profissional top!',
          createdAt: now.subtract(const Duration(days: 12)),
        ),
      ]);
    }

    // bs3 — Dom Navalha
    if (shops.containsKey('bs3')) {
      final bs3 = shops['bs3']!;
      reviews.addAll([
        ReviewModel(
          id: 'r10',
          appointmentId: 'ext_c1',
          clientId: 'ext_c8',
          clientName: 'André Vieira',
          barbershopId: 'bs3',
          barbershopName: bs3.name,
          barberId: 'b5',
          barberName: 'Marcelo Viana',
          serviceName: 'Barba VIP',
          barbershopRating: 5,
          barberRating: 5,
          comment:
              'Experiência única. A toalha quente e o óleo importado fazem toda a diferença.',
          createdAt: now.subtract(const Duration(days: 6)),
        ),
        ReviewModel(
          id: 'r11',
          appointmentId: 'ext_c2',
          clientId: 'ext_c9',
          clientName: 'Henrique Souza',
          barbershopId: 'bs3',
          barbershopName: bs3.name,
          barberId: 'b6',
          barberName: 'Fábio Reis',
          serviceName: 'Corte Premium',
          barbershopRating: 5,
          barberRating: 5,
          comment: 'Vale cada centavo. Atendimento VIP do começo ao fim.',
          createdAt: now.subtract(const Duration(days: 9)),
        ),
      ]);
    }

    return reviews;
  }
}
