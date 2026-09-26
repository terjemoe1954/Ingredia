# Ingredia App Sjekkliste

App Navn: Ingredia
Kategori: Mat og drikke / Helseverktøy
Dato: 2026-08-30

## Tilpasset Sjekkliste

- [ ] Språk: Engelsk, Norsk og Thai
- [ ] `SettingsView` har seksjon for språkvalg
- [ ] `SettingsView` har seksjon for `Utseende` med `System`, `Mørk` og `Lys`
- [ ] `SettingsView` har seksjon for `Hjelp` med `Brukerveiledning`
- [ ] `SettingsView` har seksjon for appinformasjon med `Versjon` og `Build`
- [ ] Språkbytte er testet i hele appen
- [ ] `ProfileView` har tilgang til `SettingsView`
- [ ] `HelpView` er testet på alle språk
- [ ] Utseende er testet i `System`, `Mørk` og `Lys`
- [ ] Appinformasjon er testet mot prosjektets `Versjon` og `Build`
- [ ] Førstegangsvisning for sikkerhetsinformasjon er testet
- [ ] `HistoryView` støtter sletting av enkeltprodukter
- [ ] `HistoryView` støtter tømming av historikk
- [ ] Historikkfunksjonene er testet
- [ ] Produktoppslag viser tydelig feilmelding ved `offline`, `timeout` og `not found`
- [ ] Retry-knapper for produkthenting og alternativer er testet
- [ ] Produktresultat viser `Datagrunnlag`
- [ ] Alternative produkter vurderes mot hele profilen
- [ ] Restaurantkort er testet med og uten krysskontaminering
- [ ] Appinformasjon: `Versjon` og `Build` bør vises i appen før App Store-lansering
- [ ] `User-Agent` bruker ekte support-URL før App Store-lansering
- [ ] Personvernerklæring og supportside er ferdigstilt før publisering

## Ingredia-spesifikt Innhold

1. Språk
   - Engelsk
   - Norsk
   - Thai

2. `ProfileView`
   - Allergiprofil
   - Krysskontaminering
   - Restaurantnotat
   - Tilgang til `SettingsView`

3. `SettingsView`
   - Språkvalg
   - Utseende: `System`, `Mørk`, `Lys`
   - Hjelp: `Brukerveiledning`
   - Appinformasjon: `Versjon`, `Build`

4. `HomeView`
   - Skann produkt
   - Førstegangs sikkerhetsinformasjon
   - Retry ved feil i produkthenting

5. `ProductResultView`
   - Vurdering
   - Treff mot profilen
   - Datagrunnlag
   - Bedre alternativer
   - Retry ved feil i alternativhenting

6. `HistoryView`
   - Åpne tidligere skanninger
   - Slette enkeltprodukt
   - Tømme all historikk

7. `RestaurantCardView`
   - Valgte allergener
   - Krysskontamineringsvarsel
   - Restaurantnotat

8. Før App Store
   - Vis `Versjon` og `Build` i appen
   - Sett ekte support-URL i `AppMetadata.swift`
   - Fullfør personvern- og supportdokumentasjon
   - Test på ekte enheter med strekkoder

## Vurdering Av Opprinnelig Sjekkliste

Dette bør endres fra originalen:

- `SettingsView` finnes nå i Ingredia
- `Utseende` med `System`, `Mørk` og `Lys` er implementert
- `Appinformasjon` med `Versjon` og `Build` finnes i `SettingsView`
- Hjelp finnes i `HelpView` via `SettingsView`

Dette kan beholdes som idé:

- flerspråkstøtte
- hjelpeseksjon
- versjon/build-kontroll
- testpunkter for språk og brukerflyt
