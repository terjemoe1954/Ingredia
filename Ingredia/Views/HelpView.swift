import SwiftUI

struct HelpView: View {
    @AppStorage(AppLanguage.storageKey) private var selectedLanguage = AppLanguage.norwegian.rawValue

    var body: some View {
        List {
            ForEach(helpSections) { section in
                Section(section.title) {
                    VStack(alignment: .leading, spacing: 10) {
                        ForEach(section.paragraphs, id: \.self) { paragraph in
                            Text(paragraph)
                                .font(.body)
                                .foregroundStyle(.primary)
                        }
                    }
                    .padding(.vertical, 4)
                }
            }
        }
        .navigationTitle(title)
    }

    private var language: AppLanguage {
        AppLanguage(rawValue: selectedLanguage) ?? .norwegian
    }

    private var title: String {
        switch language {
        case .norwegian:
            return "Hjelp"
        case .english:
            return "Help"
        case .thai:
            return "ช่วยเหลือ"
        }
    }

    private var helpSections: [HelpSection] {
        switch language {
        case .norwegian:
            return norwegianSections
        case .english:
            return englishSections
        case .thai:
            return thaiSections
        }
    }

    private var norwegianSections: [HelpSection] {
        [
            HelpSection(
                title: "Hva Ingredia gjør",
                paragraphs: [
                    "Ingredia hjelper deg med å vurdere matvarer mot den aktive allergiprofilen din.",
                    "Appen skanner strekkoden, henter produktdata, sammenligner disse med profilen din og kan foreslå bedre alternativer i samme kategori."
                ]
            ),
            HelpSection(
                title: "Før du begynner",
                paragraphs: [
                    "Åpne Profil og velg allergener eller intoleranser før første vurdering.",
                    "Bestem også om advarsler som «kan inneholde spor av» skal behandles som uakseptable."
                ]
            ),
            HelpSection(
                title: "Slik skanner du",
                paragraphs: [
                    "Gå til Skann og trykk på skanneknappen.",
                    "Plasser strekkoden i kameravisningen og hold telefonen rolig til koden blir registrert.",
                    "Ingredia støtter EAN-8, EAN-13, UPC-E og Code 128."
                ]
            ),
            HelpSection(
                title: "Forstå vurderingen",
                paragraphs: [
                    "Resultatet kan vise Ingen registrerte konflikter, Kontroller produktet, Ikke anbefalt eller For lite informasjon.",
                    "Ingredia viser også hvorfor produktet ble flagget og hvor komplett datagrunnlaget ser ut til å være."
                ]
            ),
            HelpSection(
                title: "Bedre alternativer",
                paragraphs: [
                    "Når et produkt har konflikt eller bør kontrolleres, kan Ingredia foreslå alternativer fra samme kategori.",
                    "Forslagene vurderes mot hele profilen din, ikke bare ett allergen."
                ]
            ),
            HelpSection(
                title: "Historikk og lokale data",
                paragraphs: [
                    "Tidligere skannede produkter lagres lokalt og kan åpnes igjen fra Historikk.",
                    "Hvis du skanner samme produkt senere, forsøker appen å hente oppdatert live-data og oppdatere den lokale lagringen."
                ]
            ),
            HelpSection(
                title: "Datakilde",
                paragraphs: [
                    "Ingredia bruker Open Food Facts som ekstern produktdatabase.",
                    "Dekningen varierer mellom land, så resultatene kan være mer komplette i noen markeder enn i andre."
                ]
            ),
            HelpSection(
                title: "Viktig sikkerhetsråd",
                paragraphs: [
                    "Ingredia garanterer aldri at et produkt er trygt.",
                    "Kontroller alltid emballasjen, ingredienslisten, sporadvarsler og produsentens siste informasjon."
                ]
            )
        ]
    }

    private var englishSections: [HelpSection] {
        [
            HelpSection(
                title: "What Ingredia does",
                paragraphs: [
                    "Ingredia helps you review food products against your active allergy profile.",
                    "The app scans the barcode, fetches product data, compares it with your profile, and may suggest better alternatives in the same category."
                ]
            ),
            HelpSection(
                title: "Before you start",
                paragraphs: [
                    "Open Profile and choose your allergens or intolerances before the first assessment.",
                    "Also decide whether \"may contain traces of\" warnings should be treated as unacceptable."
                ]
            ),
            HelpSection(
                title: "How to scan",
                paragraphs: [
                    "Go to Scan and tap the scan button.",
                    "Place the barcode inside the camera view and hold the phone steady until the code is detected.",
                    "Ingredia currently supports EAN-8, EAN-13, UPC-E, and Code 128."
                ]
            ),
            HelpSection(
                title: "Understanding the assessment",
                paragraphs: [
                    "The result may show No registered conflicts, Check the product, Not recommended, or Too little information.",
                    "Ingredia also shows why the product was flagged and how complete the data appears to be."
                ]
            ),
            HelpSection(
                title: "Better alternatives",
                paragraphs: [
                    "When a product conflicts with your profile or should be checked, Ingredia may suggest alternatives from the same category.",
                    "Suggestions are evaluated against your full profile, not only one allergen."
                ]
            ),
            HelpSection(
                title: "History and local data",
                paragraphs: [
                    "Previously scanned products are stored locally and can be reopened from History.",
                    "If you scan the same product later, the app tries to fetch newer live data and update the local record."
                ]
            ),
            HelpSection(
                title: "Data source",
                paragraphs: [
                    "Ingredia uses Open Food Facts as its external product database.",
                    "Coverage varies by country, so results may be more complete in some markets than others."
                ]
            ),
            HelpSection(
                title: "Important safety advice",
                paragraphs: [
                    "Ingredia never guarantees that a product is safe.",
                    "Always verify the packaging, ingredient list, trace warnings, and the manufacturer’s latest information."
                ]
            )
        ]
    }

    private var thaiSections: [HelpSection] {
        [
            HelpSection(
                title: "Ingredia ทำอะไร",
                paragraphs: [
                    "Ingredia ช่วยคุณตรวจสอบสินค้าอาหารเทียบกับโปรไฟล์การแพ้อาหารที่ใช้งานอยู่",
                    "แอปจะสแกนบาร์โค้ด ดึงข้อมูลสินค้า เปรียบเทียบกับโปรไฟล์ของคุณ และอาจแนะนำทางเลือกที่ดีกว่าในหมวดเดียวกัน"
                ]
            ),
            HelpSection(
                title: "ก่อนเริ่มใช้งาน",
                paragraphs: [
                    "เปิดหน้าโปรไฟล์และเลือกสารก่อภูมิแพ้หรือภาวะแพ้ก่อนการประเมินครั้งแรก",
                    "กำหนดด้วยว่าคำเตือน \"อาจมีร่องรอยของ\" ควรถูกมองว่าไม่ยอมรับได้หรือไม่"
                ]
            ),
            HelpSection(
                title: "วิธีสแกน",
                paragraphs: [
                    "ไปที่แท็บสแกนและแตะปุ่มสแกน",
                    "วางบาร์โค้ดให้อยู่ในมุมมองของกล้องและถือโทรศัพท์ให้นิ่งจนระบบตรวจพบรหัส",
                    "ปัจจุบัน Ingredia รองรับ EAN-8, EAN-13, UPC-E และ Code 128"
                ]
            ),
            HelpSection(
                title: "การอ่านผลการประเมิน",
                paragraphs: [
                    "ผลลัพธ์อาจแสดงว่า ไม่พบความขัดแย้งที่ลงทะเบียนไว้, ควรตรวจสอบสินค้า, ไม่แนะนำ, หรือ ข้อมูลไม่เพียงพอ",
                    "Ingredia ยังแสดงเหตุผลที่สินค้าถูกแจ้งเตือนและความครบถ้วนของข้อมูลด้วย"
                ]
            ),
            HelpSection(
                title: "ทางเลือกที่ดีกว่า",
                paragraphs: [
                    "เมื่อสินค้ามีความขัดแย้งกับโปรไฟล์หรือควรตรวจสอบ Ingredia อาจแนะนำทางเลือกจากหมวดเดียวกัน",
                    "คำแนะนำจะถูกประเมินเทียบกับทั้งโปรไฟล์ของคุณ ไม่ใช่เพียงสารก่อภูมิแพ้รายการเดียว"
                ]
            ),
            HelpSection(
                title: "ประวัติและข้อมูลในเครื่อง",
                paragraphs: [
                    "สินค้าที่เคยสแกนจะถูกเก็บไว้ในเครื่องและเปิดดูได้อีกจากประวัติ",
                    "หากสแกนสินค้าชิ้นเดิมอีกครั้ง แอปจะพยายามดึงข้อมูลสดใหม่และอัปเดตรายการในเครื่อง"
                ]
            ),
            HelpSection(
                title: "แหล่งข้อมูล",
                paragraphs: [
                    "Ingredia ใช้ Open Food Facts เป็นฐานข้อมูลสินค้าภายนอก",
                    "ความครอบคลุมแตกต่างกันไปในแต่ละประเทศ ดังนั้นบางตลาดอาจมีข้อมูลครบกว่าตลาดอื่น"
                ]
            ),
            HelpSection(
                title: "คำแนะนำด้านความปลอดภัย",
                paragraphs: [
                    "Ingredia ไม่รับประกันว่าสินค้าปลอดภัย",
                    "ควรตรวจสอบบรรจุภัณฑ์ รายการส่วนผสม คำเตือนเรื่องร่องรอย และข้อมูลล่าสุดจากผู้ผลิตทุกครั้ง"
                ]
            )
        ]
    }
}

private struct HelpSection: Identifiable {
    let id = UUID()
    let title: String
    let paragraphs: [String]
}
