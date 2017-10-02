#pragma reqlib "clantag"

/**
 * Transmite prin parametrul @ClanTag numele(tag-ul) clanului.
 *
 * @Param : @MemberName - Numele jucatorului.
 *          @MemberNameLen - Numarul de celule al sirului MemberName[].
 *          @ClanTag - Sirul in care se salveaza tag-ul clanului.
 *          @ClanTagLen - Numarul de celule al sirului ClanTag[].
 *          @ClanType - Tipul tagului (1 - Inaintea numelui | 0 - Dupa nume).
 *
 * @Return : Return 1 - Daca jucatorul are clan, respectiv transmite numele clanului prin parametru.
 *           Return 0 - Daca jucatorul nu are clan, functia se opreste.
 */
native getClanTag(MemberName[], MemberNameLen, ClanTag[], ClanTagLen, &ClanType);