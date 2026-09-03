import Foundation

enum AppLanguage: String, CaseIterable, Identifiable {
    case norwegian
    case english
    case thai

    static let storageKey = "selectedLanguage"

    var id: String { rawValue }

    var localeIdentifier: String {
        switch self {
        case .norwegian:
            return "nb_NO"
        case .english:
            return "en_US"
        case .thai:
            return "th_TH"
        }
    }

    var displayName: String {
        switch self {
        case .norwegian:
            return "Norsk"
        case .english:
            return "English"
        case .thai:
            return "ไทย"
        }
    }

    static var current: AppLanguage {
        let rawValue = UserDefaults.standard.string(forKey: storageKey) ?? AppLanguage.norwegian.rawValue
        return AppLanguage(rawValue: rawValue) ?? .norwegian
    }
}

enum AppTextKey {
    case tabScan
    case tabHistory
    case tabRestaurantCard
    case tabProfile
    case settings
    case scanProduct
    case loadingProductInformation
    case fetchProductFailed
    case retry
    case scanAgain
    case recentlyScanned
    case positionBarcode
    case close
    case yourProfile
    case profileReadyTitle
    case profileNotReadyTitle
    case selectedAllergens
    case noAllergensSelected
    case scanIntroTitle
    case scanIntroBody
    case chooseAllergensBeforeAssessment
    case noScansYet
    case scanFirstProduct
    case history
    case historySummaryTitle
    case historySummaryBody
    case savedScansCount
    case clearHistory
    case clearHistoryTitle
    case clearHistoryMessage
    case clearHistoryConfirm
    case cancel
    case product
    case assessment
    case profileMatches
    case betterAlternatives
    case lookingForAlternatives
    case alternativeFetchFailed
    case alternativeRetry
    case productOverviewTitle
    case scannedBarcode
    case importantToCheck
    case ingredients
    case registeredAllergens
    case mayContainTracesOf
    case advisoryDisclaimer
    case noImageAvailable
    case done
    case accessibilityStatus
    case accessibilityOpensProduct
    case accessibilitySelected
    case accessibilityNotSelected
    case accessibilitySelectedAllergens
    case accessibilityNoSelectedAllergens
    case allMyAllergens
    case crossContamination
    case rejectMayContain
    case crossContaminationDescription
    case profileDisclaimer
    case profile
    case language
    case languageDescription
    case languageSupport
    case appearance
    case appearanceDescription
    case appearanceSystem
    case appearanceDark
    case appearanceLight
    case help
    case helpDescription
    case userGuide
    case appInformation
    case version
    case build
    case dataSources
    case dataSourcesDescription
    case dataSourceActive
    case dataSourceInactive
    case dataSourceAlternativeSearchAvailable
    case dataSourceAlternativeSearchUnavailable
    case foodRepoSetupInstructions
    case safetyNoticeTitle
    case safetyNoticeHeadline
    case safetyNoticeSummary
    case safetyNoticeWhatItDoes
    case safetyNoticeWhatItDoesBody
    case safetyNoticeWhatItCannotDo
    case safetyNoticeWhatItCannotDoBody
    case safetyNoticeAlwaysCheck
    case safetyNoticeAlwaysCheckBody
    case safetyNoticeContinue
    case allergySelectionDescription
    case profileName
    case profileNameDescription
    case restaurantNote
    case restaurantNoteDescription
    case profileAutoSave
    case activeProfile
    case chooseActiveProfile
    case createNewProfile
    case newProfileDefaultName
    case duplicateProfile
    case deleteProfile
    case copiedProfileSuffix
    case restaurantCard
    case defaultProfileName
    case allergyCardTitle
    case allergyCardSubtitle
    case iMustAvoid
    case avoidCrossContamination
    case chooseAllergensForCard
    case pleaseVerifyPreparation
    case crossContaminationWarningTitle
    case showCardToStaff
    case productLookupInvalidBarcode
    case productLookupNotFound
    case productLookupBadResponse
    case productLookupOffline
    case productLookupTimedOut
    case productLookupServerIssue
    case limitedProductDataTitle
    case limitedProductDataBody
    case unknownProduct
    case safetyCompatible
    case safetyCaution
    case safetyAvoid
    case safetyUnknown
    case createProfileForAssessment
    case missingProductDataForAssessment
    case registeredAsIngredient
    case registeredAsTrace
    case basedOnProfileAndProductData
    case allowedTraceNeedsCheck
    case noRegisteredConflictsCheckPackaging
    case dataQualityHigh
    case dataQualityHighDetail
    case dataQualityLimited
    case dataQualityLimitedDetail
    case dataQualityUnknown
    case dataQualityUnknownDetail
    case productDataConfidence
    case sourceTrust
    case sourceTrustCommunity
    case sourceTrustCommunityDetail
    case sourceTrustVerified
    case sourceTrustVerifiedDetail
    case sourceTrustLimited
    case sourceTrustLimitedDetail
    case dataSource
    case productDataUpdated
    case productDataUpdatedUnavailable
    case alternativeNeedsProfile
    case alternativeOnlyForConflicts
    case alternativeMissingCategoryData
    case alternativeNoMatches
    case noRegisteredConflictsInAvailableData
    case alternativeSourceHistory
    case alternativeSourceDatabase
    case alternativeReasonSameCategory
    case alternativeReasonBetterData
    case alternativeReasonNoConflicts
    case alternativeFilterHideUnknown
    case alternativeFilterOnlyKnown
    case alternativeResetFilters
}

enum AppText {
    static func text(_ key: AppTextKey, language: AppLanguage = .current) -> String {
        switch language {
        case .norwegian:
            return norwegian(key)
        case .english:
            return english(key)
        case .thai:
            return thai(key)
        }
    }

    private static func norwegian(_ key: AppTextKey) -> String {
        switch key {
        case .tabScan: "Skann"
        case .tabHistory: "Historikk"
        case .tabRestaurantCard: "Restaurantkort"
        case .tabProfile: "Profil"
        case .settings: "Innstillinger"
        case .scanProduct: "SKANN PRODUKT"
        case .loadingProductInformation: "Henter produktinformasjon …"
        case .fetchProductFailed: "Kunne ikke hente produkt"
        case .retry: "Prøv igjen"
        case .scanAgain: "Skann på nytt"
        case .recentlyScanned: "Nylig skannet"
        case .positionBarcode: "Plasser strekkoden i kameraet"
        case .close: "Lukk"
        case .yourProfile: "Din profil"
        case .profileReadyTitle: "Profil klar"
        case .profileNotReadyTitle: "Profil mangler detaljer"
        case .selectedAllergens: "Valgte allergener"
        case .noAllergensSelected: "Ingen allergener valgt ennå"
        case .scanIntroTitle: "Skann for en rask vurdering"
        case .scanIntroBody: "Sjekk produktdata mot profilen din og få forslag til bedre alternativer når det finnes relevante treff."
        case .chooseAllergensBeforeAssessment: "Velg allergener i Profil før første vurdering."
        case .noScansYet: "Ingen skanninger ennå"
        case .scanFirstProduct: "Skann ditt første produkt fra Skann-fanen."
        case .history: "Historikk"
        case .historySummaryTitle: "Tidligere skanninger"
        case .historySummaryBody: "Åpne et produkt på nytt for å se vurderingen og eventuelle bedre alternativer."
        case .savedScansCount: "lagrede skanninger"
        case .clearHistory: "Tøm historikk"
        case .clearHistoryTitle: "Tømme historikk?"
        case .clearHistoryMessage: "Alle lagrede skanninger blir fjernet fra denne enheten."
        case .clearHistoryConfirm: "Tøm"
        case .cancel: "Avbryt"
        case .product: "Produkt"
        case .assessment: "Vurdering"
        case .profileMatches: "Treff mot profilen din"
        case .betterAlternatives: "Bedre alternativer"
        case .lookingForAlternatives: "Leter etter produkter i samme kategori …"
        case .alternativeFetchFailed: "Kunne ikke hente alternative produkter akkurat nå."
        case .alternativeRetry: "Prøv å hente alternativer igjen"
        case .productOverviewTitle: "Skannet produkt"
        case .scannedBarcode: "Strekkode"
        case .importantToCheck: "Viktig å kontrollere"
        case .ingredients: "Ingredienser"
        case .registeredAllergens: "Registrerte allergener"
        case .mayContainTracesOf: "Kan inneholde spor av"
        case .advisoryDisclaimer: "Ingredia kan redusere tiden det tar å finne relevant informasjon, men erstatter ikke etiketten, produsentinformasjon eller medisinsk rådgivning."
        case .noImageAvailable: "Ingen bilde tilgjengelig"
        case .done: "Ferdig"
        case .accessibilityStatus: "Status"
        case .accessibilityOpensProduct: "Åpner produktdetaljer"
        case .accessibilitySelected: "Valgt"
        case .accessibilityNotSelected: "Ikke valgt"
        case .accessibilitySelectedAllergens: "Valgte allergener"
        case .accessibilityNoSelectedAllergens: "Ingen allergener er valgt"
        case .allMyAllergens: "Mine allergener/intoleranser"
        case .crossContamination: "Krysskontaminering"
        case .rejectMayContain: "Avvis «kan inneholde spor av»"
        case .crossContaminationDescription: "Når dette er slått på, behandles sporadvarsler som uakseptable for profilen din."
        case .profileDisclaimer: "Ved alvorlig allergi bør produktets emballasje og produsentens siste informasjon alltid kontrolleres."
        case .profile: "Profil"
        case .language: "Språk"
        case .languageDescription: "Velg hvilket språk Ingredia skal bruke i appen og restaurantkortet."
        case .languageSupport: "Engelsk, Norsk og Thai"
        case .appearance: "Utseende"
        case .appearanceDescription: "Velg om appen skal følge systemet eller bruke lyst eller mørkt utseende."
        case .appearanceSystem: "System"
        case .appearanceDark: "Mørk"
        case .appearanceLight: "Lys"
        case .help: "Hjelp"
        case .helpDescription: "Les en kort veiledning om skanning, vurderinger, alternativer og datagrunnlag."
        case .userGuide: "Brukerveiledning"
        case .appInformation: "Appinformasjon"
        case .version: "Versjon"
        case .build: "Build"
        case .dataSources: "Datakilder"
        case .dataSourcesDescription: "Se hvilke kilder som er aktive for produktsøk og alternative varer."
        case .dataSourceActive: "Aktiv"
        case .dataSourceInactive: "Ikke aktiv"
        case .dataSourceAlternativeSearchAvailable: "Brukes også for alternative varer"
        case .dataSourceAlternativeSearchUnavailable: "Brukes bare for oppslag av enkeltprodukt"
        case .foodRepoSetupInstructions: "For å slå på Food Repo, legg inn API-nøkkelen som `FOODREPO_API_KEY` i scheme environment eller Info.plist."
        case .safetyNoticeTitle: "Viktig informasjon"
        case .safetyNoticeHeadline: "Bruk Ingredia som støtte, ikke som fasit."
        case .safetyNoticeSummary: "Ingredia hjelper deg med å finne relevant produktinformasjon raskere, men appen kan ikke garantere at en matvare er trygg."
        case .safetyNoticeWhatItDoes: "Hva appen gjør"
        case .safetyNoticeWhatItDoesBody: "Ingredia skanner strekkoder, henter tilgjengelige produktdata og sammenligner disse med allergiprofilen din."
        case .safetyNoticeWhatItCannotDo: "Hva appen ikke kan gjøre"
        case .safetyNoticeWhatItCannotDoBody: "Ingredia kan ikke bekrefte medisinsk trygghet. Produktdata kan være mangelfulle, utdaterte eller feil registrert."
        case .safetyNoticeAlwaysCheck: "Hva du alltid må kontrollere"
        case .safetyNoticeAlwaysCheckBody: "Les alltid emballasjen, ingredienslisten, allergenmerkingen, sporadvarsler og produsentens siste informasjon før du spiser produktet."
        case .safetyNoticeContinue: "Jeg forstår"
        case .allergySelectionDescription: "Velg allergenene og intoleransene som skal brukes i vurderingene dine."
        case .profileName: "Profilnavn"
        case .profileNameDescription: "Gi profilen et tydelig navn, for eksempel deg selv eller et familiemedlem."
        case .restaurantNote: "Restaurantnotat"
        case .restaurantNoteDescription: "Legg til en kort beskjed til ansatte, for eksempel hvor alvorlig reaksjonen kan være."
        case .profileAutoSave: "Endringer lagres automatisk. Trykk Ferdig for å lukke tastaturet."
        case .activeProfile: "Aktiv profil"
        case .chooseActiveProfile: "Velg hvilken profil som skal brukes i vurderinger og restaurantkort."
        case .createNewProfile: "Ny profil"
        case .newProfileDefaultName: "Ny profil"
        case .duplicateProfile: "Dupliser"
        case .deleteProfile: "Slett"
        case .copiedProfileSuffix: "kopi"
        case .restaurantCard: "Restaurantkort"
        case .defaultProfileName: "Min profil"
        case .allergyCardTitle: "ALLERGIKORT"
        case .allergyCardSubtitle: "Vis dette kortet til ansatte før du bestiller."
        case .iMustAvoid: "Jeg må unngå:"
        case .avoidCrossContamination: "Jeg må også unngå mat som kan være utsatt for krysskontaminering med disse allergenene."
        case .chooseAllergensForCard: "Velg allergener i Profil for å lage restaurantkortet."
        case .pleaseVerifyPreparation: "Vennligst kontroller ingredienser og hvordan maten tilberedes."
        case .crossContaminationWarningTitle: "Krysskontaminering må unngås"
        case .showCardToStaff: "Vis kortet tydelig til personalet og be dem bekrefte ingredienser og tilberedning."
        case .productLookupInvalidBarcode: "Ugyldig strekkode."
        case .productLookupNotFound: "Produktet ble ikke funnet i databasen."
        case .productLookupBadResponse: "Kunne ikke lese produktdata akkurat nå."
        case .productLookupOffline: "Ingen nettverkstilkobling. Kontroller forbindelsen og prøv igjen."
        case .productLookupTimedOut: "Forespørselen tok for lang tid. Prøv igjen om et øyeblikk."
        case .productLookupServerIssue: "Datakilden svarer ikke som forventet akkurat nå. Prøv igjen senere."
        case .limitedProductDataTitle: "Begrensede produktdata"
        case .limitedProductDataBody: "Open Food Facts-posten mangler nok ingrediens- eller allergeninformasjon til en trygg vurdering. Kontroller alltid emballasjen nøye."
        case .unknownProduct: "Ukjent produkt"
        case .safetyCompatible: "Ingen registrerte konflikter"
        case .safetyCaution: "Kontroller produktet"
        case .safetyAvoid: "Ikke anbefalt"
        case .safetyUnknown: "For lite informasjon"
        case .createProfileForAssessment: "Opprett en profil for å få en personlig vurdering."
        case .missingProductDataForAssessment: "Produktet mangler nok ingrediens- og allergeninformasjon til en vurdering."
        case .registeredAsIngredient: "Registrert som ingrediens/allergen."
        case .registeredAsTrace: "Registrert som mulig spor/krysskontaminering."
        case .basedOnProfileAndProductData: "Basert på registrerte produktdata og profilen din."
        case .allowedTraceNeedsCheck: "Produktet har spor-advarsler som profilen din tillater, men etiketten bør fortsatt kontrolleres."
        case .noRegisteredConflictsCheckPackaging: "Ingen registrerte allergener som kolliderer med profilen din ble funnet. Kontroller alltid emballasjen."
        case .dataQualityHigh: "Høy datakvalitet"
        case .dataQualityHighDetail: "Ingrediens- og allergendata er forholdsvis komplette."
        case .dataQualityLimited: "Begrenset informasjon"
        case .dataQualityLimitedDetail: "Noen relevante felt mangler eller er ufullstendige."
        case .dataQualityUnknown: "Ukjent datagrunnlag"
        case .dataQualityUnknownDetail: "Det finnes ikke nok data til en meningsfull vurdering."
        case .productDataConfidence: "Datagrunnlag"
        case .sourceTrust: "Kildetillit"
        case .sourceTrustCommunity: "Fellesskapsdata"
        case .sourceTrustCommunityDetail: "Dataene kommer fra åpne eller brukerdrevne kilder. De kan være nyttige, men må alltid kontrolleres mot emballasjen."
        case .sourceTrustVerified: "Verifisert kilde"
        case .sourceTrustVerifiedDetail: "Dataene kommer fra en mer kontrollert eller leverandørnær kilde, men emballasjen må fortsatt sjekkes."
        case .sourceTrustLimited: "Begrenset kilde"
        case .sourceTrustLimitedDetail: "Kilden kan hjelpe med produktidentifikasjon, men er ikke sterk nok for trygg allergivurdering alene."
        case .dataSource: "Datakilde"
        case .productDataUpdated: "Sist oppdatert"
        case .productDataUpdatedUnavailable: "Siste oppdatering er ikke tilgjengelig."
        case .alternativeNeedsProfile: "Opprett en profil for å få forslag som vurderes mot allergiene dine."
        case .alternativeOnlyForConflicts: "Bedre alternativer vises når produktet har en konflikt eller bør kontrolleres."
        case .alternativeMissingCategoryData: "Produktet mangler kategoridata, så Ingredia kan ikke finne lignende produkter ennå."
        case .alternativeNoMatches: "Ingen tydelig bedre alternativer ble funnet i tilgjengelige produktdata."
        case .noRegisteredConflictsInAvailableData: "Ingen registrerte allergener som kolliderer med profilen din ble funnet i tilgjengelige data."
        case .alternativeSourceHistory: "Fra historikk"
        case .alternativeSourceDatabase: "Fra Open Food Facts"
        case .alternativeReasonSameCategory: "Samme kategori"
        case .alternativeReasonBetterData: "Bedre datakvalitet"
        case .alternativeReasonNoConflicts: "Ingen registrerte konflikter"
        case .alternativeFilterHideUnknown: "Skjul ukjente forslag"
        case .alternativeFilterOnlyKnown: "Vis bare alternativer med tydeligere vurdering"
        case .alternativeResetFilters: "Tilbakestill filtre"
        }
    }

    private static func english(_ key: AppTextKey) -> String {
        switch key {
        case .tabScan: "Scan"
        case .tabHistory: "History"
        case .tabRestaurantCard: "Restaurant Card"
        case .tabProfile: "Profile"
        case .settings: "Settings"
        case .scanProduct: "SCAN PRODUCT"
        case .loadingProductInformation: "Fetching product information …"
        case .fetchProductFailed: "Could not fetch product"
        case .retry: "Try Again"
        case .scanAgain: "Scan Again"
        case .recentlyScanned: "Recently scanned"
        case .positionBarcode: "Place the barcode inside the camera frame"
        case .close: "Close"
        case .yourProfile: "Your profile"
        case .profileReadyTitle: "Profile ready"
        case .profileNotReadyTitle: "Profile needs details"
        case .selectedAllergens: "Selected allergens"
        case .noAllergensSelected: "No allergens selected yet"
        case .scanIntroTitle: "Scan for a quick assessment"
        case .scanIntroBody: "Check product data against your profile and get better alternatives when relevant matches are available."
        case .chooseAllergensBeforeAssessment: "Choose allergens in Profile before your first assessment."
        case .noScansYet: "No scans yet"
        case .scanFirstProduct: "Scan your first product from the Scan tab."
        case .history: "History"
        case .historySummaryTitle: "Previous scans"
        case .historySummaryBody: "Open a product again to review the assessment and any better alternatives."
        case .savedScansCount: "saved scans"
        case .clearHistory: "Clear History"
        case .clearHistoryTitle: "Clear history?"
        case .clearHistoryMessage: "All saved scans will be removed from this device."
        case .clearHistoryConfirm: "Clear"
        case .cancel: "Cancel"
        case .product: "Product"
        case .assessment: "Assessment"
        case .profileMatches: "Matches against your profile"
        case .betterAlternatives: "Better alternatives"
        case .lookingForAlternatives: "Looking for products in the same category …"
        case .alternativeFetchFailed: "Could not fetch alternative products right now."
        case .alternativeRetry: "Try loading alternatives again"
        case .productOverviewTitle: "Scanned product"
        case .scannedBarcode: "Barcode"
        case .importantToCheck: "Important to check"
        case .ingredients: "Ingredients"
        case .registeredAllergens: "Registered allergens"
        case .mayContainTracesOf: "May contain traces of"
        case .advisoryDisclaimer: "Ingredia can reduce the time it takes to find relevant information, but it does not replace the label, manufacturer information, or medical advice."
        case .noImageAvailable: "No image available"
        case .done: "Done"
        case .accessibilityStatus: "Status"
        case .accessibilityOpensProduct: "Opens product details"
        case .accessibilitySelected: "Selected"
        case .accessibilityNotSelected: "Not selected"
        case .accessibilitySelectedAllergens: "Selected allergens"
        case .accessibilityNoSelectedAllergens: "No allergens are selected"
        case .allMyAllergens: "My allergens/intolerances"
        case .crossContamination: "Cross-contamination"
        case .rejectMayContain: "Reject \"may contain traces of\""
        case .crossContaminationDescription: "When this is enabled, trace warnings are treated as unacceptable for your profile."
        case .profileDisclaimer: "For severe allergies, always verify the product packaging and the manufacturer's latest information."
        case .profile: "Profile"
        case .language: "Language"
        case .languageDescription: "Choose which language Ingredia should use in the app and restaurant card."
        case .languageSupport: "English, Norwegian, and Thai"
        case .appearance: "Appearance"
        case .appearanceDescription: "Choose whether the app should follow the system appearance or use a light or dark theme."
        case .appearanceSystem: "System"
        case .appearanceDark: "Dark"
        case .appearanceLight: "Light"
        case .help: "Help"
        case .helpDescription: "Read a short guide about scanning, assessments, alternatives, and data confidence."
        case .userGuide: "User Guide"
        case .appInformation: "App Information"
        case .version: "Version"
        case .build: "Build"
        case .dataSources: "Data Sources"
        case .dataSourcesDescription: "See which sources are active for product lookup and alternative suggestions."
        case .dataSourceActive: "Active"
        case .dataSourceInactive: "Inactive"
        case .dataSourceAlternativeSearchAvailable: "Also used for alternative products"
        case .dataSourceAlternativeSearchUnavailable: "Used only for single-product lookup"
        case .foodRepoSetupInstructions: "To enable Food Repo, add the API key as `FOODREPO_API_KEY` in the scheme environment or Info.plist."
        case .safetyNoticeTitle: "Important Information"
        case .safetyNoticeHeadline: "Use Ingredia as support, not as a guarantee."
        case .safetyNoticeSummary: "Ingredia helps you find relevant product information faster, but the app cannot guarantee that a food product is safe."
        case .safetyNoticeWhatItDoes: "What the app does"
        case .safetyNoticeWhatItDoesBody: "Ingredia scans barcodes, fetches available product data, and compares that data with your allergy profile."
        case .safetyNoticeWhatItCannotDo: "What the app cannot do"
        case .safetyNoticeWhatItCannotDoBody: "Ingredia cannot confirm medical safety. Product data may be incomplete, outdated, or incorrect."
        case .safetyNoticeAlwaysCheck: "What you must always check"
        case .safetyNoticeAlwaysCheckBody: "Always read the packaging, ingredient list, allergen labeling, trace warnings, and the manufacturer’s latest information before eating the product."
        case .safetyNoticeContinue: "I Understand"
        case .allergySelectionDescription: "Choose the allergens and intolerances that should be used in your assessments."
        case .profileName: "Profile name"
        case .profileNameDescription: "Give the profile a clear name, such as yourself or a family member."
        case .restaurantNote: "Restaurant note"
        case .restaurantNoteDescription: "Add a short note for staff, for example how serious the reaction may be."
        case .profileAutoSave: "Changes are saved automatically. Tap Done to dismiss the keyboard."
        case .activeProfile: "Active profile"
        case .chooseActiveProfile: "Choose which profile should be used for assessments and the restaurant card."
        case .createNewProfile: "New profile"
        case .newProfileDefaultName: "New profile"
        case .duplicateProfile: "Duplicate"
        case .deleteProfile: "Delete"
        case .copiedProfileSuffix: "copy"
        case .restaurantCard: "Restaurant Card"
        case .defaultProfileName: "My profile"
        case .allergyCardTitle: "ALLERGY CARD"
        case .allergyCardSubtitle: "Show this card to staff before ordering."
        case .iMustAvoid: "I must avoid:"
        case .avoidCrossContamination: "I must also avoid food that may be exposed to cross-contamination with these allergens."
        case .chooseAllergensForCard: "Choose allergens in Profile to create the restaurant card."
        case .pleaseVerifyPreparation: "Please verify ingredients and how the food is prepared."
        case .crossContaminationWarningTitle: "Cross-contamination must be avoided"
        case .showCardToStaff: "Show this card clearly to staff and ask them to confirm ingredients and preparation."
        case .productLookupInvalidBarcode: "Invalid barcode."
        case .productLookupNotFound: "The product was not found in the database."
        case .productLookupBadResponse: "Could not read product data right now."
        case .productLookupOffline: "No network connection. Check your connection and try again."
        case .productLookupTimedOut: "The request took too long. Please try again in a moment."
        case .productLookupServerIssue: "The data source is not responding as expected right now. Please try again later."
        case .limitedProductDataTitle: "Limited product data"
        case .limitedProductDataBody: "The Open Food Facts record lacks enough ingredient or allergen information for a reliable assessment. Always check the packaging carefully."
        case .unknownProduct: "Unknown product"
        case .safetyCompatible: "No registered conflicts"
        case .safetyCaution: "Check the product"
        case .safetyAvoid: "Not recommended"
        case .safetyUnknown: "Too little information"
        case .createProfileForAssessment: "Create a profile to get a personal assessment."
        case .missingProductDataForAssessment: "The product lacks enough ingredient and allergen information for an assessment."
        case .registeredAsIngredient: "Registered as an ingredient/allergen."
        case .registeredAsTrace: "Registered as a possible trace/cross-contamination warning."
        case .basedOnProfileAndProductData: "Based on registered product data and your profile."
        case .allowedTraceNeedsCheck: "The product has trace warnings your profile allows, but the label should still be checked."
        case .noRegisteredConflictsCheckPackaging: "No registered allergens conflicting with your profile were found. Always check the packaging."
        case .dataQualityHigh: "High data quality"
        case .dataQualityHighDetail: "Ingredient and allergen data are relatively complete."
        case .dataQualityLimited: "Limited information"
        case .dataQualityLimitedDetail: "Some relevant fields are missing or incomplete."
        case .dataQualityUnknown: "Unknown data basis"
        case .dataQualityUnknownDetail: "There is not enough data for a meaningful assessment."
        case .productDataConfidence: "Data confidence"
        case .sourceTrust: "Source trust"
        case .sourceTrustCommunity: "Community data"
        case .sourceTrustCommunityDetail: "The data comes from open or community-driven sources. It can be useful, but it should always be checked against the packaging."
        case .sourceTrustVerified: "Verified source"
        case .sourceTrustVerifiedDetail: "The data comes from a more controlled or supplier-adjacent source, but the packaging must still be checked."
        case .sourceTrustLimited: "Limited source"
        case .sourceTrustLimitedDetail: "The source may help identify the product, but it is not strong enough for safe allergy assessment on its own."
        case .dataSource: "Data source"
        case .productDataUpdated: "Last updated"
        case .productDataUpdatedUnavailable: "The latest update is not available."
        case .alternativeNeedsProfile: "Create a profile to get suggestions evaluated against your allergens."
        case .alternativeOnlyForConflicts: "Better alternatives appear when the product has a conflict or should be checked."
        case .alternativeMissingCategoryData: "The product lacks category data, so Ingredia cannot find similar products yet."
        case .alternativeNoMatches: "No clearly better alternatives were found in the available product data."
        case .noRegisteredConflictsInAvailableData: "No registered allergens conflicting with your profile were found in the available data."
        case .alternativeSourceHistory: "From history"
        case .alternativeSourceDatabase: "From Open Food Facts"
        case .alternativeReasonSameCategory: "Same category"
        case .alternativeReasonBetterData: "Better data quality"
        case .alternativeReasonNoConflicts: "No registered conflicts"
        case .alternativeFilterHideUnknown: "Hide unknown suggestions"
        case .alternativeFilterOnlyKnown: "Show only alternatives with a clearer assessment"
        case .alternativeResetFilters: "Reset filters"
        }
    }

    private static func thai(_ key: AppTextKey) -> String {
        switch key {
        case .tabScan: "สแกน"
        case .tabHistory: "ประวัติ"
        case .tabRestaurantCard: "บัตรร้านอาหาร"
        case .tabProfile: "โปรไฟล์"
        case .settings: "การตั้งค่า"
        case .scanProduct: "สแกนสินค้า"
        case .loadingProductInformation: "กำลังดึงข้อมูลสินค้า …"
        case .fetchProductFailed: "ไม่สามารถดึงข้อมูลสินค้าได้"
        case .retry: "ลองอีกครั้ง"
        case .scanAgain: "สแกนอีกครั้ง"
        case .recentlyScanned: "สแกนล่าสุด"
        case .positionBarcode: "วางบาร์โค้ดให้อยู่ในกรอบกล้อง"
        case .close: "ปิด"
        case .yourProfile: "โปรไฟล์ของคุณ"
        case .profileReadyTitle: "โปรไฟล์พร้อมใช้งาน"
        case .profileNotReadyTitle: "โปรไฟล์ยังไม่ครบ"
        case .selectedAllergens: "สารก่อภูมิแพ้ที่เลือก"
        case .noAllergensSelected: "ยังไม่ได้เลือกสารก่อภูมิแพ้"
        case .scanIntroTitle: "สแกนเพื่อประเมินอย่างรวดเร็ว"
        case .scanIntroBody: "ตรวจสอบข้อมูลสินค้ากับโปรไฟล์ของคุณ และรับคำแนะนำทางเลือกที่ดีกว่าเมื่อมีข้อมูลที่เกี่ยวข้อง."
        case .chooseAllergensBeforeAssessment: "เลือกสารก่อภูมิแพ้ในโปรไฟล์ก่อนการประเมินครั้งแรก"
        case .noScansYet: "ยังไม่มีการสแกน"
        case .scanFirstProduct: "สแกนสินค้าชิ้นแรกจากแท็บสแกน"
        case .history: "ประวัติ"
        case .historySummaryTitle: "การสแกนก่อนหน้า"
        case .historySummaryBody: "เปิดสินค้าอีกครั้งเพื่อดูผลการประเมินและทางเลือกที่ดีกว่าหากมี"
        case .savedScansCount: "รายการสแกนที่บันทึกไว้"
        case .clearHistory: "ล้างประวัติ"
        case .clearHistoryTitle: "ล้างประวัติ?"
        case .clearHistoryMessage: "รายการสแกนที่บันทึกไว้ทั้งหมดจะถูกลบออกจากอุปกรณ์นี้"
        case .clearHistoryConfirm: "ล้าง"
        case .cancel: "ยกเลิก"
        case .product: "สินค้า"
        case .assessment: "การประเมิน"
        case .profileMatches: "รายการที่ตรงกับโปรไฟล์ของคุณ"
        case .betterAlternatives: "ทางเลือกที่ดีกว่า"
        case .lookingForAlternatives: "กำลังค้นหาสินค้าในหมวดเดียวกัน …"
        case .alternativeFetchFailed: "ไม่สามารถดึงสินค้าทางเลือกได้ในขณะนี้"
        case .alternativeRetry: "ลองดึงสินค้าทางเลือกอีกครั้ง"
        case .productOverviewTitle: "สินค้าที่สแกน"
        case .scannedBarcode: "บาร์โค้ด"
        case .importantToCheck: "สิ่งสำคัญที่ต้องตรวจสอบ"
        case .ingredients: "ส่วนผสม"
        case .registeredAllergens: "สารก่อภูมิแพ้ที่ระบุไว้"
        case .mayContainTracesOf: "อาจมีร่องรอยของ"
        case .advisoryDisclaimer: "Ingredia ช่วยลดเวลาที่ใช้ในการค้นหาข้อมูลที่เกี่ยวข้องได้ แต่ไม่สามารถทดแทนฉลากสินค้า ข้อมูลจากผู้ผลิต หรือคำแนะนำทางการแพทย์ได้"
        case .noImageAvailable: "ไม่มีรูปภาพ"
        case .done: "เสร็จสิ้น"
        case .accessibilityStatus: "สถานะ"
        case .accessibilityOpensProduct: "เปิดรายละเอียดสินค้า"
        case .accessibilitySelected: "เลือกแล้ว"
        case .accessibilityNotSelected: "ยังไม่เลือก"
        case .accessibilitySelectedAllergens: "สารก่อภูมิแพ้ที่เลือก"
        case .accessibilityNoSelectedAllergens: "ยังไม่ได้เลือกสารก่อภูมิแพ้"
        case .allMyAllergens: "สารก่อภูมิแพ้/ภาวะแพ้ของฉัน"
        case .crossContamination: "การปนเปื้อนข้าม"
        case .rejectMayContain: "ปฏิเสธ \"อาจมีร่องรอยของ\""
        case .crossContaminationDescription: "เมื่อเปิดใช้งาน คำเตือนเรื่องร่องรอยจะถูกมองว่าไม่ยอมรับได้สำหรับโปรไฟล์ของคุณ"
        case .profileDisclaimer: "หากมีอาการแพ้รุนแรง ควรตรวจสอบบรรจุภัณฑ์สินค้าและข้อมูลล่าสุดจากผู้ผลิตเสมอ"
        case .profile: "โปรไฟล์"
        case .language: "ภาษา"
        case .languageDescription: "เลือกภาษาที่ Ingredia ควรใช้ในแอปและบัตรร้านอาหาร"
        case .languageSupport: "อังกฤษ นอร์เวย์ และไทย"
        case .appearance: "ลักษณะการแสดงผล"
        case .appearanceDescription: "เลือกให้แอปใช้ตามระบบ หรือใช้โหมดสว่างหรือมืด"
        case .appearanceSystem: "ระบบ"
        case .appearanceDark: "มืด"
        case .appearanceLight: "สว่าง"
        case .help: "ช่วยเหลือ"
        case .helpDescription: "อ่านคู่มือสั้น ๆ เกี่ยวกับการสแกน การประเมิน ทางเลือก และความน่าเชื่อถือของข้อมูล"
        case .userGuide: "คู่มือการใช้งาน"
        case .appInformation: "ข้อมูลแอป"
        case .version: "เวอร์ชัน"
        case .build: "บิลด์"
        case .dataSources: "แหล่งข้อมูล"
        case .dataSourcesDescription: "ดูว่าแหล่งข้อมูลใดกำลังใช้งานสำหรับการค้นหาสินค้าและสินค้าแนะนำ"
        case .dataSourceActive: "เปิดใช้งาน"
        case .dataSourceInactive: "ยังไม่เปิดใช้งาน"
        case .dataSourceAlternativeSearchAvailable: "ใช้สำหรับค้นหาสินค้าทางเลือกด้วย"
        case .dataSourceAlternativeSearchUnavailable: "ใช้เฉพาะการค้นหาสินค้าเดี่ยว"
        case .foodRepoSetupInstructions: "หากต้องการเปิดใช้ Food Repo ให้เพิ่มคีย์ API เป็น `FOODREPO_API_KEY` ใน scheme environment หรือ Info.plist"
        case .safetyNoticeTitle: "ข้อมูลสำคัญ"
        case .safetyNoticeHeadline: "ใช้ Ingredia เป็นตัวช่วย ไม่ใช่ข้อยืนยัน"
        case .safetyNoticeSummary: "Ingredia ช่วยให้คุณค้นหาข้อมูลสินค้าที่เกี่ยวข้องได้เร็วขึ้น แต่แอปไม่สามารถรับประกันได้ว่าอาหารนั้นปลอดภัย"
        case .safetyNoticeWhatItDoes: "แอปทำอะไร"
        case .safetyNoticeWhatItDoesBody: "Ingredia สแกนบาร์โค้ด ดึงข้อมูลสินค้าที่มีอยู่ และเปรียบเทียบข้อมูลนั้นกับโปรไฟล์การแพ้อาหารของคุณ"
        case .safetyNoticeWhatItCannotDo: "แอปทำอะไรไม่ได้"
        case .safetyNoticeWhatItCannotDoBody: "Ingredia ไม่สามารถยืนยันความปลอดภัยทางการแพทย์ได้ ข้อมูลสินค้าอาจไม่ครบ ล้าสมัย หรือไม่ถูกต้อง"
        case .safetyNoticeAlwaysCheck: "สิ่งที่ต้องตรวจสอบทุกครั้ง"
        case .safetyNoticeAlwaysCheckBody: "ควรอ่านบรรจุภัณฑ์ รายการส่วนผสม การระบุสารก่อภูมิแพ้ คำเตือนเรื่องร่องรอย และข้อมูลล่าสุดจากผู้ผลิตก่อนรับประทานทุกครั้ง"
        case .safetyNoticeContinue: "ฉันเข้าใจ"
        case .allergySelectionDescription: "เลือกสารก่อภูมิแพ้และภาวะแพ้ที่ควรใช้ในการประเมินของคุณ"
        case .profileName: "ชื่อโปรไฟล์"
        case .profileNameDescription: "ตั้งชื่อโปรไฟล์ให้ชัดเจน เช่น ชื่อตัวคุณเองหรือสมาชิกในครอบครัว"
        case .restaurantNote: "หมายเหตุสำหรับร้านอาหาร"
        case .restaurantNoteDescription: "เพิ่มข้อความสั้น ๆ สำหรับพนักงาน เช่น ความรุนแรงของอาการแพ้"
        case .profileAutoSave: "การเปลี่ยนแปลงจะถูกบันทึกอัตโนมัติ แตะ เสร็จสิ้น เพื่อปิดแป้นพิมพ์"
        case .activeProfile: "โปรไฟล์ที่ใช้งาน"
        case .chooseActiveProfile: "เลือกโปรไฟล์ที่จะใช้สำหรับการประเมินและบัตรร้านอาหาร"
        case .createNewProfile: "โปรไฟล์ใหม่"
        case .newProfileDefaultName: "โปรไฟล์ใหม่"
        case .duplicateProfile: "ทำสำเนา"
        case .deleteProfile: "ลบ"
        case .copiedProfileSuffix: "สำเนา"
        case .restaurantCard: "บัตรร้านอาหาร"
        case .defaultProfileName: "โปรไฟล์ของฉัน"
        case .allergyCardTitle: "บัตรแจ้งการแพ้อาหาร"
        case .allergyCardSubtitle: "โปรดแสดงบัตรนี้ให้พนักงานดูก่อนสั่งอาหาร"
        case .iMustAvoid: "ฉันต้องหลีกเลี่ยง:"
        case .avoidCrossContamination: "ฉันต้องหลีกเลี่ยงอาหารที่อาจมีการปนเปื้อนข้ามกับสารก่อภูมิแพ้เหล่านี้ด้วย"
        case .chooseAllergensForCard: "เลือกสารก่อภูมิแพ้ในโปรไฟล์เพื่อสร้างบัตรร้านอาหาร"
        case .pleaseVerifyPreparation: "โปรดตรวจสอบส่วนผสมและวิธีการเตรียมอาหาร"
        case .crossContaminationWarningTitle: "ต้องหลีกเลี่ยงการปนเปื้อนข้าม"
        case .showCardToStaff: "แสดงบัตรนี้ให้พนักงานเห็นชัดเจน และขอให้ยืนยันส่วนผสมและวิธีการเตรียมอาหาร"
        case .productLookupInvalidBarcode: "บาร์โค้ดไม่ถูกต้อง"
        case .productLookupNotFound: "ไม่พบสินค้าในฐานข้อมูล"
        case .productLookupBadResponse: "ไม่สามารถอ่านข้อมูลสินค้าได้ในขณะนี้"
        case .productLookupOffline: "ไม่มีการเชื่อมต่อเครือข่าย โปรดตรวจสอบการเชื่อมต่อแล้วลองอีกครั้ง"
        case .productLookupTimedOut: "คำขอใช้เวลานานเกินไป โปรดลองอีกครั้งในอีกสักครู่"
        case .productLookupServerIssue: "แหล่งข้อมูลไม่ตอบสนองตามปกติในขณะนี้ โปรดลองอีกครั้งภายหลัง"
        case .limitedProductDataTitle: "ข้อมูลสินค้ามีจำกัด"
        case .limitedProductDataBody: "รายการจาก Open Food Facts มีข้อมูลส่วนผสมหรือสารก่อภูมิแพ้ไม่เพียงพอสำหรับการประเมินที่เชื่อถือได้ โปรดตรวจสอบบรรจุภัณฑ์อย่างละเอียดเสมอ"
        case .unknownProduct: "สินค้าไม่ทราบชื่อ"
        case .safetyCompatible: "ไม่พบความขัดแย้งที่ลงทะเบียนไว้"
        case .safetyCaution: "ควรตรวจสอบสินค้า"
        case .safetyAvoid: "ไม่แนะนำ"
        case .safetyUnknown: "ข้อมูลไม่เพียงพอ"
        case .createProfileForAssessment: "สร้างโปรไฟล์เพื่อรับการประเมินเฉพาะบุคคล"
        case .missingProductDataForAssessment: "สินค้านี้มีข้อมูลส่วนผสมและสารก่อภูมิแพ้ไม่เพียงพอสำหรับการประเมิน"
        case .registeredAsIngredient: "ระบุว่าเป็นส่วนผสม/สารก่อภูมิแพ้"
        case .registeredAsTrace: "ระบุว่าอาจมีร่องรอยหรือการปนเปื้อนข้าม"
        case .basedOnProfileAndProductData: "อ้างอิงจากข้อมูลสินค้าที่มีอยู่และโปรไฟล์ของคุณ"
        case .allowedTraceNeedsCheck: "สินค้านี้มีคำเตือนเรื่องร่องรอยที่โปรไฟล์ของคุณอนุญาต แต่ยังควรตรวจสอบฉลากต่อไป"
        case .noRegisteredConflictsCheckPackaging: "ไม่พบสารก่อภูมิแพ้ที่ลงทะเบียนไว้ซึ่งขัดแย้งกับโปรไฟล์ของคุณ ควรตรวจสอบบรรจุภัณฑ์เสมอ"
        case .dataQualityHigh: "คุณภาพข้อมูลสูง"
        case .dataQualityHighDetail: "ข้อมูลส่วนผสมและสารก่อภูมิแพ้ค่อนข้างครบถ้วน"
        case .dataQualityLimited: "ข้อมูลจำกัด"
        case .dataQualityLimitedDetail: "ข้อมูลสำคัญบางส่วนขาดหายหรือไม่ครบถ้วน"
        case .dataQualityUnknown: "ฐานข้อมูลไม่ชัดเจน"
        case .dataQualityUnknownDetail: "มีข้อมูลไม่เพียงพอสำหรับการประเมินที่มีความหมาย"
        case .productDataConfidence: "ความน่าเชื่อถือของข้อมูล"
        case .sourceTrust: "ความน่าเชื่อถือของแหล่งข้อมูล"
        case .sourceTrustCommunity: "ข้อมูลจากชุมชน"
        case .sourceTrustCommunityDetail: "ข้อมูลมาจากแหล่งเปิดหรือชุมชนผู้ใช้ ซึ่งมีประโยชน์ได้ แต่ต้องตรวจสอบกับฉลากสินค้าทุกครั้ง"
        case .sourceTrustVerified: "แหล่งข้อมูลที่ตรวจสอบแล้ว"
        case .sourceTrustVerifiedDetail: "ข้อมูลมาจากแหล่งที่มีการควบคุมมากขึ้นหรือใกล้ผู้ผลิตมากขึ้น แต่ยังต้องตรวจสอบบรรจุภัณฑ์ทุกครั้ง"
        case .sourceTrustLimited: "แหล่งข้อมูลจำกัด"
        case .sourceTrustLimitedDetail: "แหล่งข้อมูลนี้ช่วยระบุสินค้าได้ แต่ยังไม่เพียงพอสำหรับการประเมินอาการแพ้อย่างปลอดภัยเพียงลำพัง"
        case .dataSource: "แหล่งข้อมูล"
        case .productDataUpdated: "อัปเดตล่าสุด"
        case .productDataUpdatedUnavailable: "ไม่มีข้อมูลเวลาอัปเดตล่าสุด"
        case .alternativeNeedsProfile: "สร้างโปรไฟล์เพื่อรับคำแนะนำที่ประเมินตามสารก่อภูมิแพ้ของคุณ"
        case .alternativeOnlyForConflicts: "ทางเลือกที่ดีกว่าจะแสดงเมื่อสินค้ามีความขัดแย้งหรือต้องตรวจสอบ"
        case .alternativeMissingCategoryData: "สินค้านี้ไม่มีข้อมูลหมวดหมู่ ดังนั้น Ingredia จึงยังหาสินค้าที่คล้ายกันไม่ได้"
        case .alternativeNoMatches: "ไม่พบทางเลือกที่ดีกว่าอย่างชัดเจนจากข้อมูลสินค้าที่มีอยู่"
        case .noRegisteredConflictsInAvailableData: "ไม่พบสารก่อภูมิแพ้ที่ลงทะเบียนไว้ซึ่งขัดแย้งกับโปรไฟล์ของคุณในข้อมูลที่มีอยู่"
        case .alternativeSourceHistory: "จากประวัติ"
        case .alternativeSourceDatabase: "จาก Open Food Facts"
        case .alternativeReasonSameCategory: "หมวดหมู่เดียวกัน"
        case .alternativeReasonBetterData: "คุณภาพข้อมูลดีกว่า"
        case .alternativeReasonNoConflicts: "ไม่พบความขัดแย้งที่ลงทะเบียนไว้"
        case .alternativeFilterHideUnknown: "ซ่อนคำแนะนำที่ไม่ชัดเจน"
        case .alternativeFilterOnlyKnown: "แสดงเฉพาะทางเลือกที่มีการประเมินชัดเจนกว่า"
        case .alternativeResetFilters: "รีเซ็ตตัวกรอง"
        }
    }
}
