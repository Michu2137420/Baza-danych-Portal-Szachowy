PGDMP                      }           Portal_Szachowy    17.2    17.2 i    M           0    0    ENCODING    ENCODING        SET client_encoding = 'UTF8';
                           false            N           0    0 
   STDSTRINGS 
   STDSTRINGS     (   SET standard_conforming_strings = 'on';
                           false            O           0    0 
   SEARCHPATH 
   SEARCHPATH     8   SELECT pg_catalog.set_config('search_path', '', false);
                           false            P           1262    16386    Portal_Szachowy    DATABASE     �   CREATE DATABASE "Portal_Szachowy" WITH TEMPLATE = template0 ENCODING = 'UTF8' LOCALE_PROVIDER = libc LOCALE = 'Polish_Poland.1250';
 !   DROP DATABASE "Portal_Szachowy";
                     postgres    false                       1255    17869 3   aktualizuj_elo(integer, integer, character varying) 	   PROCEDURE     H  CREATE PROCEDURE public.aktualizuj_elo(IN id_gracz_bialy integer, IN id_gracz_czarny integer, IN wynik character varying)
    LANGUAGE plpgsql
    AS $$
DECLARE
    bialy_zmiana INTEGER;
    czarny_zmiana INTEGER;
BEGIN
    IF wynik = '1-0' THEN
        bialy_zmiana := 3;  
        czarny_zmiana := -3;
    ELSIF wynik = '0-1' THEN
        bialy_zmiana := -3; 
        czarny_zmiana := 3;
    ELSE
        bialy_zmiana := 0;  
        czarny_zmiana := 0;
    END IF;

    IF NOT EXISTS (SELECT 1 FROM GRACZE WHERE ID_GRACZ = id_gracz_bialy) THEN
        RAISE EXCEPTION 'Rollback: Gracz biały o ID % nie istnieje.', id_gracz_bialy;
    END IF;

    IF NOT EXISTS (SELECT 1 FROM GRACZE WHERE ID_GRACZ = id_gracz_czarny) THEN
        RAISE EXCEPTION 'Rollback: Gracz czarny o ID % nie istnieje.', id_gracz_czarny;
    END IF;

    UPDATE GRACZE
    SET RANKING = RANKING + bialy_zmiana
    WHERE ID_GRACZ = id_gracz_bialy;

    UPDATE GRACZE
    SET RANKING = RANKING + czarny_zmiana
    WHERE ID_GRACZ = id_gracz_czarny;

    IF wynik = '1-0' THEN
        UPDATE KONTA
        SET Wygrane_Partie = Wygrane_Partie + 1
        WHERE ID_GRACZ = id_gracz_bialy;

        UPDATE KONTA
        SET Przegrane_Partie = Przegrane_Partie + 1
        WHERE ID_GRACZ = id_gracz_czarny;
        
    ELSIF wynik = '0-1' THEN
        UPDATE KONTA
        SET Wygrane_Partie = Wygrane_Partie + 1
        WHERE ID_GRACZ = id_gracz_czarny;

        UPDATE KONTA
        SET Przegrane_Partie = Przegrane_Partie + 1
        WHERE ID_GRACZ = id_gracz_bialy;
        
    ELSE
        UPDATE KONTA
        SET Remisy = Remisy + 1
        WHERE ID_GRACZ = id_gracz_bialy;

        UPDATE KONTA
        SET Remisy = Remisy + 1
        WHERE ID_GRACZ = id_gracz_czarny;
    END IF;

    COMMIT;
    RAISE NOTICE 'Commit: Ranking i statystyki graczy zaktualizowane pomyślnie.';
END;
$$;
 y   DROP PROCEDURE public.aktualizuj_elo(IN id_gracz_bialy integer, IN id_gracz_czarny integer, IN wynik character varying);
       public               postgres    false                        1255    17154 *   dodaj_gracza_do_turnieju(integer, integer)    FUNCTION     '  CREATE FUNCTION public.dodaj_gracza_do_turnieju(id_p_do_dod integer, id_t_do_dod integer) RETURNS character varying
    LANGUAGE plpgsql
    AS $$
DECLARE
    komunikat_wyniku_operacji VARCHAR(255);
    liczba_partii_w_tabeli INT;
    liczba_partii_w_turnieju INT;
BEGIN

    IF NOT EXISTS (SELECT 1 FROM TURNIEJE WHERE ID_TURNIEJU = Id_T_Do_Dod AND Status_Turnieju = 'Otwarty') THEN
        komunikat_wyniku_operacji := 'Turniej o podanym ID nie istnieje lub nie jest otwarty.';
        RAISE NOTICE 'Turniej o podanym ID % nie istnieje lub nie jest otwarty.', Id_T_Do_Dod;
    ELSE

        SELECT COUNT(Id_Partii) INTO liczba_partii_w_turnieju
        FROM PARTIE_TURNIEJE
        WHERE ID_PARTII = Id_P_Do_Dod AND ID_TURNIEJU = Id_T_Do_Dod;

        IF liczba_partii_w_turnieju > 0 THEN
            komunikat_wyniku_operacji := 'Ta partia jest już przypisana do tego turnieju (tym samym gracz).';
            RAISE NOTICE 'Partia o ID % jest już przypisana do turnieju %.', Id_P_Do_Dod, Id_T_Do_Dod;
        ELSE

            SELECT COUNT(Id_Partii) INTO liczba_partii_w_tabeli
            FROM PARTIE
            WHERE ID_PARTII = Id_P_Do_Dod;

            IF liczba_partii_w_tabeli = 0 THEN
                komunikat_wyniku_operacji := 'Partia o podanym ID nie istnieje.';
                RAISE NOTICE 'Partia o ID % nie istnieje w bazie danych.', Id_P_Do_Dod;
            ELSE

                INSERT INTO PARTIE_TURNIEJE (ID_TURNIEJU, ID_PARTII)
                VALUES (Id_T_Do_Dod, Id_P_Do_Dod);
                
                komunikat_wyniku_operacji := 'Partia została dodana do turnieju (tym samym gracz).';
                RAISE NOTICE 'Partia o ID % została dodana do turnieju %.', Id_P_Do_Dod, Id_T_Do_Dod;
            END IF;
        END IF;
    END IF;
    

    RETURN komunikat_wyniku_operacji;

END;
$$;
 Y   DROP FUNCTION public.dodaj_gracza_do_turnieju(id_p_do_dod integer, id_t_do_dod integer);
       public               postgres    false            �            1255    17156    losowy_komentarz()    FUNCTION       CREATE FUNCTION public.losowy_komentarz() RETURNS character varying
    LANGUAGE plpgsql
    AS $$
DECLARE
    v_komentarz VARCHAR(255);
BEGIN
    SELECT komentarz INTO v_komentarz
    FROM (
        VALUES
            ('Świetna partia!'),
            ('Bardzo wyrównana gra!'),
            ('Dobra strategia, gratulacje!'),
            ('Mój przeciwnik był trudnym rywalem!'),
            ('Skradzione zwycięstwo!'),
            ('Zremisowaliśmy, ale było ciekawie.'),
            ('Zdecydowane zwycięstwo, dobrze grane!'),
            ('Podziwiam opanowanie w tej grze!'),
            ('Fajna gra, czekam na rewanż!'),
            ('Dużo szczęścia, ale w końcu wygrałem!')
    ) AS komentarze(komentarz)
    ORDER BY RANDOM()
    LIMIT 1;

    RETURN v_komentarz;
END;
$$;
 )   DROP FUNCTION public.losowy_komentarz();
       public               postgres    false                       1255    17155 #   najpopularniejsze_tryby_rozgrywek()    FUNCTION       CREATE FUNCTION public.najpopularniejsze_tryby_rozgrywek() RETURNS character varying
    LANGUAGE plpgsql
    AS $$
DECLARE
    v_tryb_rozgrywki VARCHAR(255);
    v_liczba_wystapien INTEGER DEFAULT 0;
    max_wystapien INTEGER DEFAULT 0;
    popularny_tryb VARCHAR(255) DEFAULT NULL;
    cur REFCURSOR;
BEGIN
    OPEN cur FOR 
        SELECT p.TRYB_ROZGRYWKI, COUNT(p.TRYB_ROZGRYWKI) AS liczba_wystapien
        FROM PARTIE p
        GROUP BY p.TRYB_ROZGRYWKI
        ORDER BY liczba_wystapien DESC;
    
    FETCH cur INTO v_tryb_rozgrywki, v_liczba_wystapien;
    RAISE NOTICE 'Rozpoczęcie przetwarzania danych dla trybów rozgrywki.';
    
    WHILE FOUND LOOP
        RAISE NOTICE 'Analizowany tryb: %, liczba wystąpień: %', v_tryb_rozgrywki, v_liczba_wystapien;
        
        IF v_liczba_wystapien > max_wystapien THEN
            max_wystapien := v_liczba_wystapien;
            popularny_tryb := v_tryb_rozgrywki;
            RAISE NOTICE 'Nowy najpopularniejszy tryb: % z % wystąpieniami.', popularny_tryb, max_wystapien;
        END IF;
        
        FETCH cur INTO v_tryb_rozgrywki, v_liczba_wystapien;
    END LOOP;
    
    CLOSE cur;
    
    RAISE NOTICE 'Przetwarzanie zakończone. Najpopularniejszy tryb: %', popularny_tryb;
    
    RETURN popularny_tryb;
END;
$$;
 :   DROP FUNCTION public.najpopularniejsze_tryby_rozgrywek();
       public               postgres    false            �            1255    17667    ocena_do_partii_trigger()    FUNCTION     �  CREATE FUNCTION public.ocena_do_partii_trigger() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
DECLARE
    random_konto INT;
BEGIN
    SELECT ID_KONTA INTO random_konto
    FROM KONTA 
    ORDER BY RANDOM()
    LIMIT 1;

    INSERT INTO OCENY (ID_PARTII, ID_KONTA, RATING_PARTII, KOMENTARZ)
    VALUES (
        (SELECT MAX(ID_PARTII) FROM PARTIE),  
        random_konto,  
        ROUND(1 + (RANDOM() * 9)),  
        LOSOWY_KOMENTARZ()  
    );

    RETURN NEW;
END;
$$;
 0   DROP FUNCTION public.ocena_do_partii_trigger();
       public               postgres    false                       1255    17508 $   stworzenie_konta_po_dodaniu_gracza()    FUNCTION     -  CREATE FUNCTION public.stworzenie_konta_po_dodaniu_gracza() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
DECLARE
    v_email VARCHAR(100);
    v_wygrane INTEGER;
    v_porazki INTEGER;
    v_remisy INTEGER;
    v_data_zalozenia DATE;
    v_id_konta INTEGER;
BEGIN
    v_email := 'gracz' || NEW.ID_GRACZ || '@example.com';

    IF NEW.RANKING > 2000 THEN
        v_wygrane := 100;
        v_porazki := 10;
        v_remisy := 5;
    ELSIF NEW.RANKING BETWEEN 1500 AND 2000 THEN
        v_wygrane := 80;
        v_porazki := 20;
        v_remisy := 10;
    ELSE
        v_wygrane := 50;
        v_porazki := 40;
        v_remisy := 30;
    END IF;

    v_data_zalozenia := CURRENT_DATE;

    INSERT INTO KONTA (ID_GRACZ, EMAIL, DATA_ZALOZENIA, WYGRANE_PARTIE, PRZEGRANE_PARTIE, REMISY)
    VALUES (NEW.ID_GRACZ, v_email, v_data_zalozenia, v_wygrane, v_porazki, v_remisy);

    SELECT ID_KONTA INTO v_id_konta
    FROM KONTA
    WHERE ID_GRACZ = NEW.ID_GRACZ;

    UPDATE GRACZE
    SET ID_KONTA = v_id_konta
    WHERE ID_GRACZ = NEW.ID_GRACZ;

    RETURN NEW;
END;
$$;
 ;   DROP FUNCTION public.stworzenie_konta_po_dodaniu_gracza();
       public               postgres    false            �            1255    17158    update_popularne_otwarcia() 	   PROCEDURE     %  CREATE PROCEDURE public.update_popularne_otwarcia()
    LANGUAGE plpgsql
    AS $$
DECLARE
    otwarcie_id INTEGER;
    nowa_liczba_wystapien INTEGER;
    aktualna_liczba_wystapien INTEGER;
    cur CURSOR FOR 
        SELECT ID_OTWARCIA, COUNT(ID_OTWARCIA) AS LICZBA_WYSTAPIEN
        FROM PARTIE
        GROUP BY ID_OTWARCIA;
BEGIN
    OPEN cur;

    LOOP
        FETCH cur INTO otwarcie_id, nowa_liczba_wystapien;
        EXIT WHEN NOT FOUND;

        SELECT COALESCE(LICZBA_WYSTAPIEN, 0) INTO aktualna_liczba_wystapien
        FROM OTWARCIA
        WHERE ID_OTWARCIA = otwarcie_id;

        IF aktualna_liczba_wystapien <> nowa_liczba_wystapien THEN
            UPDATE OTWARCIA
            SET LICZBA_WYSTAPIEN = nowa_liczba_wystapien
            WHERE ID_OTWARCIA = otwarcie_id;
        END IF;

        IF NOT EXISTS (SELECT 1 FROM OTWARCIA WHERE ID_OTWARCIA = otwarcie_id) THEN
            INSERT INTO OTWARCIA (ID_OTWARCIA, LICZBA_WYSTAPIEN)
            VALUES (otwarcie_id, nowa_liczba_wystapien);
        END IF;
    END LOOP;

    CLOSE cur;
END;
$$;
 3   DROP PROCEDURE public.update_popularne_otwarcia();
       public               postgres    false                       1255    17513 !   updatepopularneotwarcia_trigger()    FUNCTION     9  CREATE FUNCTION public.updatepopularneotwarcia_trigger() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
DECLARE
    ranking_bialy INT;
    ranking_czarny INT;
BEGIN
    CALL Update_Popularne_Otwarcia();

    SELECT RANKING INTO ranking_bialy FROM GRACZE WHERE ID_GRACZ = NEW.ID_GRACZ_BIALY;
    SELECT RANKING INTO ranking_czarny FROM GRACZE WHERE ID_GRACZ = NEW.ID_GRACZ_CZARNY;

    IF ranking_bialy >= 2500 THEN
        UPDATE GRACZE SET TYTUL = 'GM' WHERE ID_GRACZ = NEW.ID_GRACZ_BIALY;
    ELSIF ranking_bialy BETWEEN 2400 AND 2499 THEN
        UPDATE GRACZE SET TYTUL = 'IM' WHERE ID_GRACZ = NEW.ID_GRACZ_BIALY;
    ELSIF ranking_bialy BETWEEN 2200 AND 2399 THEN
        UPDATE GRACZE SET TYTUL = 'FM' WHERE ID_GRACZ = NEW.ID_GRACZ_BIALY;
    ELSIF ranking_bialy BETWEEN 2000 AND 2199 THEN
        UPDATE GRACZE SET TYTUL = 'CM' WHERE ID_GRACZ = NEW.ID_GRACZ_BIALY;
    ELSE
        UPDATE GRACZE SET TYTUL = NULL WHERE ID_GRACZ = NEW.ID_GRACZ_BIALY;
    END IF;

    IF ranking_czarny >= 2500 THEN
        UPDATE GRACZE SET TYTUL = 'GM' WHERE ID_GRACZ = NEW.ID_GRACZ_CZARNY;
    ELSIF ranking_czarny BETWEEN 2400 AND 2499 THEN
        UPDATE GRACZE SET TYTUL = 'IM' WHERE ID_GRACZ = NEW.ID_GRACZ_CZARNY;
    ELSIF ranking_czarny BETWEEN 2200 AND 2399 THEN
        UPDATE GRACZE SET TYTUL = 'FM' WHERE ID_GRACZ = NEW.ID_GRACZ_CZARNY;
    ELSIF ranking_czarny BETWEEN 2000 AND 2199 THEN
        UPDATE GRACZE SET TYTUL = 'CM' WHERE ID_GRACZ = NEW.ID_GRACZ_CZARNY;
    ELSE
        UPDATE GRACZE SET TYTUL = NULL WHERE ID_GRACZ = NEW.ID_GRACZ_CZARNY;
    END IF;

    RETURN NEW;
END;
$$;
 8   DROP FUNCTION public.updatepopularneotwarcia_trigger();
       public               postgres    false                       1255    17159    usun_gracza(integer) 	   PROCEDURE     �  CREATE PROCEDURE public.usun_gracza(IN do_usunienia integer)
    LANGUAGE plpgsql
    AS $$
DECLARE
    Gracz_Do_usunienia INTEGER;
BEGIN

    SELECT ID_KONTA 
    INTO Gracz_Do_usunienia
    FROM GRACZE
    WHERE ID_GRACZ = Do_usunienia;


    IF Gracz_Do_usunienia IS NULL THEN
        RETURN;
    END IF;


    CREATE TEMP TABLE Tym_Zadania (
        ID_ZADANIA INTEGER
    ) ON COMMIT DROP;


    INSERT INTO Tym_Zadania (ID_ZADANIA)
    SELECT ID_ZADANIA
    FROM KONTA_ZADANIA
    WHERE ID_KONTA = Gracz_Do_usunienia;


    DELETE FROM KONTA_ZADANIA
    WHERE ID_KONTA = Gracz_Do_usunienia;


    UPDATE ZADANIA
    SET STAN_ROZWIAZANIA = 0
    WHERE ID_ZADANIA IN (SELECT ID_ZADANIA FROM Tym_Zadania);


    DELETE FROM OCENY
    WHERE ID_KONTA = Gracz_Do_usunienia;


    DELETE FROM GRACZE
    WHERE ID_GRACZ = Do_usunienia;


    DELETE FROM KONTA
    WHERE ID_KONTA = Gracz_Do_usunienia;

END;
$$;
 <   DROP PROCEDURE public.usun_gracza(IN do_usunienia integer);
       public               postgres    false            �            1259    17693    gracze    TABLE     ~  CREATE TABLE public.gracze (
    id_gracz integer NOT NULL,
    id_trenera integer,
    id_konta integer,
    nazwisko_gracza character varying(40),
    imie_gracza character varying(30),
    kraj_pochodzenia character varying(30),
    tytul character varying(20),
    ranking integer NOT NULL,
    data_urodzenia date,
    CONSTRAINT gracze_ranking_check CHECK ((ranking >= 0))
);
    DROP TABLE public.gracze;
       public         heap r       postgres    false            �            1259    17692    gracze_id_gracz_seq    SEQUENCE     �   CREATE SEQUENCE public.gracze_id_gracz_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
 *   DROP SEQUENCE public.gracze_id_gracz_seq;
       public               postgres    false    220            Q           0    0    gracze_id_gracz_seq    SEQUENCE OWNED BY     K   ALTER SEQUENCE public.gracze_id_gracz_seq OWNED BY public.gracze.id_gracz;
          public               postgres    false    219            �            1259    17701    konta    TABLE       CREATE TABLE public.konta (
    id_konta integer NOT NULL,
    id_gracz integer NOT NULL,
    email character varying(30) NOT NULL,
    data_zalozenia date NOT NULL,
    wygrane_partie integer DEFAULT 0,
    przegrane_partie integer DEFAULT 0,
    remisy integer DEFAULT 0
);
    DROP TABLE public.konta;
       public         heap r       postgres    false            �            1259    17700    konta_id_konta_seq    SEQUENCE     �   CREATE SEQUENCE public.konta_id_konta_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
 )   DROP SEQUENCE public.konta_id_konta_seq;
       public               postgres    false    222            R           0    0    konta_id_konta_seq    SEQUENCE OWNED BY     I   ALTER SEQUENCE public.konta_id_konta_seq OWNED BY public.konta.id_konta;
          public               postgres    false    221            �            1259    17712    konta_zadania    TABLE     f   CREATE TABLE public.konta_zadania (
    id_konta integer NOT NULL,
    id_zadania integer NOT NULL
);
 !   DROP TABLE public.konta_zadania;
       public         heap r       postgres    false            �            1259    17718    oceny    TABLE     �   CREATE TABLE public.oceny (
    id_oceny integer NOT NULL,
    id_partii integer NOT NULL,
    id_konta integer NOT NULL,
    rating_partii integer,
    komentarz character varying(200)
);
    DROP TABLE public.oceny;
       public         heap r       postgres    false            �            1259    17717    oceny_id_oceny_seq    SEQUENCE     �   CREATE SEQUENCE public.oceny_id_oceny_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
 )   DROP SEQUENCE public.oceny_id_oceny_seq;
       public               postgres    false    225            S           0    0    oceny_id_oceny_seq    SEQUENCE OWNED BY     I   ALTER SEQUENCE public.oceny_id_oceny_seq OWNED BY public.oceny.id_oceny;
          public               postgres    false    224            �            1259    17725    otwarcia    TABLE     �   CREATE TABLE public.otwarcia (
    id_otwarcia integer NOT NULL,
    nazwa_otwarcia character varying(40) NOT NULL,
    liczba_wystapien integer DEFAULT 0
);
    DROP TABLE public.otwarcia;
       public         heap r       postgres    false            �            1259    17724    otwarcia_id_otwarcia_seq    SEQUENCE     �   CREATE SEQUENCE public.otwarcia_id_otwarcia_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
 /   DROP SEQUENCE public.otwarcia_id_otwarcia_seq;
       public               postgres    false    227            T           0    0    otwarcia_id_otwarcia_seq    SEQUENCE OWNED BY     U   ALTER SEQUENCE public.otwarcia_id_otwarcia_seq OWNED BY public.otwarcia.id_otwarcia;
          public               postgres    false    226            �            1259    17733    partie    TABLE     �  CREATE TABLE public.partie (
    id_partii integer NOT NULL,
    id_gracz_bialy integer NOT NULL,
    id_otwarcia integer,
    id_sedziego integer NOT NULL,
    id_gracz_czarny integer NOT NULL,
    tryb_rozgrywki character varying(30) NOT NULL,
    czas_na_gracza_min integer NOT NULL,
    czas_na_gracza_sek integer,
    zapis_partii text,
    wynik character varying(10) NOT NULL
);
    DROP TABLE public.partie;
       public         heap r       postgres    false            �            1259    17741    partie_turnieje    TABLE     j   CREATE TABLE public.partie_turnieje (
    id_turnieju integer NOT NULL,
    id_partii integer NOT NULL
);
 #   DROP TABLE public.partie_turnieje;
       public         heap r       postgres    false            �            1259    17765    turnieje    TABLE     �   CREATE TABLE public.turnieje (
    id_turnieju integer NOT NULL,
    nazwa_turnieju character varying(100) NOT NULL,
    tryb_turnieju character varying(30),
    status_turnieju character varying(20) NOT NULL
);
    DROP TABLE public.turnieje;
       public         heap r       postgres    false            �            1259    17844    partie_arcymistrzow    VIEW       CREATE VIEW public.partie_arcymistrzow AS
 SELECT DISTINCT concat(g_bialy.imie_gracza, ' ', g_bialy.nazwisko_gracza) AS "Bialy Zwyciezca",
    concat(g_czarny.imie_gracza, ' ', g_czarny.nazwisko_gracza) AS "Czarny Zwyciezca",
    g_bialy.ranking AS "Elo Bialy",
    g_czarny.ranking AS "Elo Czarny",
    ((g_bialy.ranking + g_czarny.ranking) / 2) AS "Srednie Elo",
    COALESCE(t.nazwa_turnieju, 'Brak Turnieju'::character varying) AS "Turniej",
    o.nazwa_otwarcia AS "Otwarcie",
    COALESCE(((length(p.zapis_partii) - length(replace(p.zapis_partii, ' '::text, ''::text))) / 3), 0) AS "Liczba Posuniec W Partii",
    p.czas_na_gracza_min AS "Czas na Gracza (min)",
    p.tryb_rozgrywki AS "Tryb Rozgrywki",
    p.zapis_partii AS "Zapis PGN",
    p.id_partii
   FROM (((((public.partie p
     JOIN public.gracze g_bialy ON ((p.id_gracz_bialy = g_bialy.id_gracz)))
     JOIN public.gracze g_czarny ON ((p.id_gracz_czarny = g_czarny.id_gracz)))
     LEFT JOIN public.partie_turnieje pt ON ((p.id_partii = pt.id_partii)))
     LEFT JOIN public.turnieje t ON ((pt.id_turnieju = t.id_turnieju)))
     JOIN public.otwarcia o ON ((p.id_otwarcia = o.id_otwarcia)))
  WHERE (((g_bialy.tytul)::text = 'GM'::text) OR ((g_czarny.tytul)::text = 'GM'::text))
  ORDER BY ((g_bialy.ranking + g_czarny.ranking) / 2) DESC;
 &   DROP VIEW public.partie_arcymistrzow;
       public       v       postgres    false    236    229    229    229    229    229    227    227    220    220    220    220    220    229    229    230    230    236            �            1259    17732    partie_id_partii_seq    SEQUENCE     �   CREATE SEQUENCE public.partie_id_partii_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
 +   DROP SEQUENCE public.partie_id_partii_seq;
       public               postgres    false    229            U           0    0    partie_id_partii_seq    SEQUENCE OWNED BY     M   ALTER SEQUENCE public.partie_id_partii_seq OWNED BY public.partie.id_partii;
          public               postgres    false    228            �            1259    17747 	   sedziowie    TABLE     �   CREATE TABLE public.sedziowie (
    id_sedziego integer NOT NULL,
    nazwisko_sedziego character varying(40) NOT NULL,
    imie_sedziego character varying(40) NOT NULL,
    tel character varying(9),
    akredytacja_pzszach integer NOT NULL
);
    DROP TABLE public.sedziowie;
       public         heap r       postgres    false            �            1259    17746    sedziowie_id_sedziego_seq    SEQUENCE     �   CREATE SEQUENCE public.sedziowie_id_sedziego_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
 0   DROP SEQUENCE public.sedziowie_id_sedziego_seq;
       public               postgres    false    232            V           0    0    sedziowie_id_sedziego_seq    SEQUENCE OWNED BY     W   ALTER SEQUENCE public.sedziowie_id_sedziego_seq OWNED BY public.sedziowie.id_sedziego;
          public               postgres    false    231            �            1259    17756    trenerzy    TABLE     �   CREATE TABLE public.trenerzy (
    id_trenera integer NOT NULL,
    nazwisko_trenera character varying(40) NOT NULL,
    imie_trenera character varying(30) NOT NULL,
    email_trenera character varying(30),
    ranking_trenera integer
);
    DROP TABLE public.trenerzy;
       public         heap r       postgres    false            �            1259    17755    trenerzy_id_trenera_seq    SEQUENCE     �   CREATE SEQUENCE public.trenerzy_id_trenera_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
 .   DROP SEQUENCE public.trenerzy_id_trenera_seq;
       public               postgres    false    234            W           0    0    trenerzy_id_trenera_seq    SEQUENCE OWNED BY     S   ALTER SEQUENCE public.trenerzy_id_trenera_seq OWNED BY public.trenerzy.id_trenera;
          public               postgres    false    233            �            1259    17764    turnieje_id_turnieju_seq    SEQUENCE     �   CREATE SEQUENCE public.turnieje_id_turnieju_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
 /   DROP SEQUENCE public.turnieje_id_turnieju_seq;
       public               postgres    false    236            X           0    0    turnieje_id_turnieju_seq    SEQUENCE OWNED BY     U   ALTER SEQUENCE public.turnieje_id_turnieju_seq OWNED BY public.turnieje.id_turnieju;
          public               postgres    false    235            �            1259    17849    wyniki_turniejow    MATERIALIZED VIEW     �  CREATE MATERIALIZED VIEW public.wyniki_turniejow AS
 SELECT t.id_turnieju,
    t.nazwa_turnieju,
    concat(g.imie_gracza, ' ', g.nazwisko_gracza) AS gracz,
    sum(
        CASE
            WHEN ((p.id_gracz_bialy = g.id_gracz) AND ((p.wynik)::text = '1-0'::text)) THEN (1)::numeric
            WHEN ((p.id_gracz_bialy = g.id_gracz) AND ((p.wynik)::text = '0-1'::text)) THEN (0)::numeric
            WHEN ((p.id_gracz_bialy = g.id_gracz) AND ((p.wynik)::text = '1/2-1/2'::text)) THEN 0.5
            ELSE (0)::numeric
        END) AS punkty_bialymi,
    sum(
        CASE
            WHEN ((p.id_gracz_czarny = g.id_gracz) AND ((p.wynik)::text = '0-1'::text)) THEN (1)::numeric
            WHEN ((p.id_gracz_czarny = g.id_gracz) AND ((p.wynik)::text = '1-0'::text)) THEN (0)::numeric
            WHEN ((p.id_gracz_czarny = g.id_gracz) AND ((p.wynik)::text = '1/2-1/2'::text)) THEN 0.5
            ELSE (0)::numeric
        END) AS punkty_czarnymi,
    sum(
        CASE
            WHEN ((p.id_gracz_bialy = g.id_gracz) AND ((p.wynik)::text = '1-0'::text)) THEN (1)::numeric
            WHEN ((p.id_gracz_bialy = g.id_gracz) AND ((p.wynik)::text = '0-1'::text)) THEN (0)::numeric
            WHEN ((p.id_gracz_czarny = g.id_gracz) AND ((p.wynik)::text = '0-1'::text)) THEN (1)::numeric
            WHEN ((p.id_gracz_czarny = g.id_gracz) AND ((p.wynik)::text = '1-0'::text)) THEN (0)::numeric
            WHEN (((p.id_gracz_bialy = g.id_gracz) OR (p.id_gracz_czarny = g.id_gracz)) AND ((p.wynik)::text = '1/2-1/2'::text)) THEN 0.5
            ELSE (0)::numeric
        END) AS punkty_ogolnie
   FROM (((public.partie_turnieje pt
     JOIN public.partie p ON ((pt.id_partii = p.id_partii)))
     JOIN public.turnieje t ON ((pt.id_turnieju = t.id_turnieju)))
     JOIN public.gracze g ON (((g.id_gracz = p.id_gracz_bialy) OR (g.id_gracz = p.id_gracz_czarny))))
  GROUP BY t.id_turnieju, t.nazwa_turnieju, g.id_gracz, g.imie_gracza, g.nazwisko_gracza
  WITH NO DATA;
 0   DROP MATERIALIZED VIEW public.wyniki_turniejow;
       public         heap m       postgres    false    220    220    220    229    229    229    229    230    230    236    236            �            1259    17772    zadania    TABLE     �   CREATE TABLE public.zadania (
    id_zadania integer NOT NULL,
    poziom_trudnosci integer,
    stan_rozwiazania integer NOT NULL
);
    DROP TABLE public.zadania;
       public         heap r       postgres    false            �            1259    17771    zadania_id_zadania_seq    SEQUENCE     �   CREATE SEQUENCE public.zadania_id_zadania_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
 -   DROP SEQUENCE public.zadania_id_zadania_seq;
       public               postgres    false    238            Y           0    0    zadania_id_zadania_seq    SEQUENCE OWNED BY     Q   ALTER SEQUENCE public.zadania_id_zadania_seq OWNED BY public.zadania.id_zadania;
          public               postgres    false    237            �            1259    17861    zadania_szachowe    VIEW     �  CREATE VIEW public.zadania_szachowe AS
 SELECT k.id_konta AS "numer konta",
    k.email AS "e-mail konta",
    concat(g.imie_gracza, ' ', g.nazwisko_gracza) AS "Imie i Nazwisko Wlasciciela",
    count(
        CASE
            WHEN (z.stan_rozwiazania = 1) THEN 1
            ELSE NULL::integer
        END) AS "Rozwiazane",
    (round(avg(
        CASE
            WHEN (z.stan_rozwiazania = 1) THEN z.poziom_trudnosci
            ELSE NULL::integer
        END), 2))::numeric(10,2) AS "srednia trudnosc wykonanych zadan",
    sum(
        CASE
            WHEN ((z.stan_rozwiazania = 1) AND (z.poziom_trudnosci >= 2000)) THEN 10
            WHEN ((z.stan_rozwiazania = 1) AND ((z.poziom_trudnosci >= 1500) AND (z.poziom_trudnosci <= 1999))) THEN 7
            WHEN ((z.stan_rozwiazania = 1) AND ((z.poziom_trudnosci >= 1000) AND (z.poziom_trudnosci <= 1499))) THEN 4
            WHEN ((z.stan_rozwiazania = 1) AND ((z.poziom_trudnosci >= 500) AND (z.poziom_trudnosci <= 999))) THEN 2
            WHEN ((z.stan_rozwiazania = 1) AND (z.poziom_trudnosci < 500)) THEN 1
            ELSE 0
        END) AS "przyrost ELO"
   FROM (((public.konta_zadania kz
     JOIN public.zadania z ON ((kz.id_zadania = z.id_zadania)))
     JOIN public.konta k ON ((kz.id_konta = k.id_konta)))
     JOIN public.gracze g ON ((g.id_gracz = k.id_gracz)))
  GROUP BY k.id_konta, k.email, g.imie_gracza, g.nazwisko_gracza
  ORDER BY (sum(
        CASE
            WHEN ((z.stan_rozwiazania = 1) AND (z.poziom_trudnosci >= 2000)) THEN 10
            WHEN ((z.stan_rozwiazania = 1) AND ((z.poziom_trudnosci >= 1500) AND (z.poziom_trudnosci <= 1999))) THEN 7
            WHEN ((z.stan_rozwiazania = 1) AND ((z.poziom_trudnosci >= 1000) AND (z.poziom_trudnosci <= 1499))) THEN 4
            WHEN ((z.stan_rozwiazania = 1) AND ((z.poziom_trudnosci >= 500) AND (z.poziom_trudnosci <= 999))) THEN 2
            WHEN ((z.stan_rozwiazania = 1) AND (z.poziom_trudnosci < 500)) THEN 1
            ELSE 0
        END)) DESC;
 #   DROP VIEW public.zadania_szachowe;
       public       v       postgres    false    220    220    222    222    222    223    220    223    238    238    238            h           2604    17696    gracze id_gracz    DEFAULT     r   ALTER TABLE ONLY public.gracze ALTER COLUMN id_gracz SET DEFAULT nextval('public.gracze_id_gracz_seq'::regclass);
 >   ALTER TABLE public.gracze ALTER COLUMN id_gracz DROP DEFAULT;
       public               postgres    false    219    220    220            i           2604    17704    konta id_konta    DEFAULT     p   ALTER TABLE ONLY public.konta ALTER COLUMN id_konta SET DEFAULT nextval('public.konta_id_konta_seq'::regclass);
 =   ALTER TABLE public.konta ALTER COLUMN id_konta DROP DEFAULT;
       public               postgres    false    222    221    222            m           2604    17721    oceny id_oceny    DEFAULT     p   ALTER TABLE ONLY public.oceny ALTER COLUMN id_oceny SET DEFAULT nextval('public.oceny_id_oceny_seq'::regclass);
 =   ALTER TABLE public.oceny ALTER COLUMN id_oceny DROP DEFAULT;
       public               postgres    false    224    225    225            n           2604    17728    otwarcia id_otwarcia    DEFAULT     |   ALTER TABLE ONLY public.otwarcia ALTER COLUMN id_otwarcia SET DEFAULT nextval('public.otwarcia_id_otwarcia_seq'::regclass);
 C   ALTER TABLE public.otwarcia ALTER COLUMN id_otwarcia DROP DEFAULT;
       public               postgres    false    227    226    227            p           2604    17736    partie id_partii    DEFAULT     t   ALTER TABLE ONLY public.partie ALTER COLUMN id_partii SET DEFAULT nextval('public.partie_id_partii_seq'::regclass);
 ?   ALTER TABLE public.partie ALTER COLUMN id_partii DROP DEFAULT;
       public               postgres    false    228    229    229            q           2604    17750    sedziowie id_sedziego    DEFAULT     ~   ALTER TABLE ONLY public.sedziowie ALTER COLUMN id_sedziego SET DEFAULT nextval('public.sedziowie_id_sedziego_seq'::regclass);
 D   ALTER TABLE public.sedziowie ALTER COLUMN id_sedziego DROP DEFAULT;
       public               postgres    false    232    231    232            r           2604    17759    trenerzy id_trenera    DEFAULT     z   ALTER TABLE ONLY public.trenerzy ALTER COLUMN id_trenera SET DEFAULT nextval('public.trenerzy_id_trenera_seq'::regclass);
 B   ALTER TABLE public.trenerzy ALTER COLUMN id_trenera DROP DEFAULT;
       public               postgres    false    234    233    234            s           2604    17768    turnieje id_turnieju    DEFAULT     |   ALTER TABLE ONLY public.turnieje ALTER COLUMN id_turnieju SET DEFAULT nextval('public.turnieje_id_turnieju_seq'::regclass);
 C   ALTER TABLE public.turnieje ALTER COLUMN id_turnieju DROP DEFAULT;
       public               postgres    false    235    236    236            t           2604    17775    zadania id_zadania    DEFAULT     x   ALTER TABLE ONLY public.zadania ALTER COLUMN id_zadania SET DEFAULT nextval('public.zadania_id_zadania_seq'::regclass);
 A   ALTER TABLE public.zadania ALTER COLUMN id_zadania DROP DEFAULT;
       public               postgres    false    238    237    238            7          0    17693    gracze 
   TABLE DATA           �   COPY public.gracze (id_gracz, id_trenera, id_konta, nazwisko_gracza, imie_gracza, kraj_pochodzenia, tytul, ranking, data_urodzenia) FROM stdin;
    public               postgres    false    220   ��       9          0    17701    konta 
   TABLE DATA           t   COPY public.konta (id_konta, id_gracz, email, data_zalozenia, wygrane_partie, przegrane_partie, remisy) FROM stdin;
    public               postgres    false    222   t�       :          0    17712    konta_zadania 
   TABLE DATA           =   COPY public.konta_zadania (id_konta, id_zadania) FROM stdin;
    public               postgres    false    223   ��       <          0    17718    oceny 
   TABLE DATA           X   COPY public.oceny (id_oceny, id_partii, id_konta, rating_partii, komentarz) FROM stdin;
    public               postgres    false    225   ��       >          0    17725    otwarcia 
   TABLE DATA           Q   COPY public.otwarcia (id_otwarcia, nazwa_otwarcia, liczba_wystapien) FROM stdin;
    public               postgres    false    227   ��       @          0    17733    partie 
   TABLE DATA           �   COPY public.partie (id_partii, id_gracz_bialy, id_otwarcia, id_sedziego, id_gracz_czarny, tryb_rozgrywki, czas_na_gracza_min, czas_na_gracza_sek, zapis_partii, wynik) FROM stdin;
    public               postgres    false    229   ��       A          0    17741    partie_turnieje 
   TABLE DATA           A   COPY public.partie_turnieje (id_turnieju, id_partii) FROM stdin;
    public               postgres    false    230   ��       C          0    17747 	   sedziowie 
   TABLE DATA           l   COPY public.sedziowie (id_sedziego, nazwisko_sedziego, imie_sedziego, tel, akredytacja_pzszach) FROM stdin;
    public               postgres    false    232   @�       E          0    17756    trenerzy 
   TABLE DATA           n   COPY public.trenerzy (id_trenera, nazwisko_trenera, imie_trenera, email_trenera, ranking_trenera) FROM stdin;
    public               postgres    false    234   ��       G          0    17765    turnieje 
   TABLE DATA           _   COPY public.turnieje (id_turnieju, nazwa_turnieju, tryb_turnieju, status_turnieju) FROM stdin;
    public               postgres    false    236   ��       I          0    17772    zadania 
   TABLE DATA           Q   COPY public.zadania (id_zadania, poziom_trudnosci, stan_rozwiazania) FROM stdin;
    public               postgres    false    238   )�       Z           0    0    gracze_id_gracz_seq    SEQUENCE SET     B   SELECT pg_catalog.setval('public.gracze_id_gracz_seq', 15, true);
          public               postgres    false    219            [           0    0    konta_id_konta_seq    SEQUENCE SET     A   SELECT pg_catalog.setval('public.konta_id_konta_seq', 15, true);
          public               postgres    false    221            \           0    0    oceny_id_oceny_seq    SEQUENCE SET     A   SELECT pg_catalog.setval('public.oceny_id_oceny_seq', 21, true);
          public               postgres    false    224            ]           0    0    otwarcia_id_otwarcia_seq    SEQUENCE SET     G   SELECT pg_catalog.setval('public.otwarcia_id_otwarcia_seq', 15, true);
          public               postgres    false    226            ^           0    0    partie_id_partii_seq    SEQUENCE SET     C   SELECT pg_catalog.setval('public.partie_id_partii_seq', 24, true);
          public               postgres    false    228            _           0    0    sedziowie_id_sedziego_seq    SEQUENCE SET     G   SELECT pg_catalog.setval('public.sedziowie_id_sedziego_seq', 6, true);
          public               postgres    false    231            `           0    0    trenerzy_id_trenera_seq    SEQUENCE SET     E   SELECT pg_catalog.setval('public.trenerzy_id_trenera_seq', 5, true);
          public               postgres    false    233            a           0    0    turnieje_id_turnieju_seq    SEQUENCE SET     F   SELECT pg_catalog.setval('public.turnieje_id_turnieju_seq', 2, true);
          public               postgres    false    235            b           0    0    zadania_id_zadania_seq    SEQUENCE SET     F   SELECT pg_catalog.setval('public.zadania_id_zadania_seq', 194, true);
          public               postgres    false    237            w           2606    17699    gracze gracze_pkey 
   CONSTRAINT     V   ALTER TABLE ONLY public.gracze
    ADD CONSTRAINT gracze_pkey PRIMARY KEY (id_gracz);
 <   ALTER TABLE ONLY public.gracze DROP CONSTRAINT gracze_pkey;
       public                 postgres    false    220            y           2606    17711    konta konta_email_key 
   CONSTRAINT     Q   ALTER TABLE ONLY public.konta
    ADD CONSTRAINT konta_email_key UNIQUE (email);
 ?   ALTER TABLE ONLY public.konta DROP CONSTRAINT konta_email_key;
       public                 postgres    false    222            {           2606    17709    konta konta_pkey 
   CONSTRAINT     T   ALTER TABLE ONLY public.konta
    ADD CONSTRAINT konta_pkey PRIMARY KEY (id_konta);
 :   ALTER TABLE ONLY public.konta DROP CONSTRAINT konta_pkey;
       public                 postgres    false    222            }           2606    17716     konta_zadania konta_zadania_pkey 
   CONSTRAINT     p   ALTER TABLE ONLY public.konta_zadania
    ADD CONSTRAINT konta_zadania_pkey PRIMARY KEY (id_konta, id_zadania);
 J   ALTER TABLE ONLY public.konta_zadania DROP CONSTRAINT konta_zadania_pkey;
       public                 postgres    false    223    223                       2606    17723    oceny oceny_pkey 
   CONSTRAINT     T   ALTER TABLE ONLY public.oceny
    ADD CONSTRAINT oceny_pkey PRIMARY KEY (id_oceny);
 :   ALTER TABLE ONLY public.oceny DROP CONSTRAINT oceny_pkey;
       public                 postgres    false    225            �           2606    17731    otwarcia otwarcia_pkey 
   CONSTRAINT     ]   ALTER TABLE ONLY public.otwarcia
    ADD CONSTRAINT otwarcia_pkey PRIMARY KEY (id_otwarcia);
 @   ALTER TABLE ONLY public.otwarcia DROP CONSTRAINT otwarcia_pkey;
       public                 postgres    false    227            �           2606    17740    partie partie_pkey 
   CONSTRAINT     W   ALTER TABLE ONLY public.partie
    ADD CONSTRAINT partie_pkey PRIMARY KEY (id_partii);
 <   ALTER TABLE ONLY public.partie DROP CONSTRAINT partie_pkey;
       public                 postgres    false    229            �           2606    17745 $   partie_turnieje partie_turnieje_pkey 
   CONSTRAINT     v   ALTER TABLE ONLY public.partie_turnieje
    ADD CONSTRAINT partie_turnieje_pkey PRIMARY KEY (id_turnieju, id_partii);
 N   ALTER TABLE ONLY public.partie_turnieje DROP CONSTRAINT partie_turnieje_pkey;
       public                 postgres    false    230    230            �           2606    17754 +   sedziowie sedziowie_akredytacja_pzszach_key 
   CONSTRAINT     u   ALTER TABLE ONLY public.sedziowie
    ADD CONSTRAINT sedziowie_akredytacja_pzszach_key UNIQUE (akredytacja_pzszach);
 U   ALTER TABLE ONLY public.sedziowie DROP CONSTRAINT sedziowie_akredytacja_pzszach_key;
       public                 postgres    false    232            �           2606    17752    sedziowie sedziowie_pkey 
   CONSTRAINT     _   ALTER TABLE ONLY public.sedziowie
    ADD CONSTRAINT sedziowie_pkey PRIMARY KEY (id_sedziego);
 B   ALTER TABLE ONLY public.sedziowie DROP CONSTRAINT sedziowie_pkey;
       public                 postgres    false    232            �           2606    17763 #   trenerzy trenerzy_email_trenera_key 
   CONSTRAINT     g   ALTER TABLE ONLY public.trenerzy
    ADD CONSTRAINT trenerzy_email_trenera_key UNIQUE (email_trenera);
 M   ALTER TABLE ONLY public.trenerzy DROP CONSTRAINT trenerzy_email_trenera_key;
       public                 postgres    false    234            �           2606    17761    trenerzy trenerzy_pkey 
   CONSTRAINT     \   ALTER TABLE ONLY public.trenerzy
    ADD CONSTRAINT trenerzy_pkey PRIMARY KEY (id_trenera);
 @   ALTER TABLE ONLY public.trenerzy DROP CONSTRAINT trenerzy_pkey;
       public                 postgres    false    234            �           2606    17770    turnieje turnieje_pkey 
   CONSTRAINT     ]   ALTER TABLE ONLY public.turnieje
    ADD CONSTRAINT turnieje_pkey PRIMARY KEY (id_turnieju);
 @   ALTER TABLE ONLY public.turnieje DROP CONSTRAINT turnieje_pkey;
       public                 postgres    false    236            �           2606    17777    zadania zadania_pkey 
   CONSTRAINT     Z   ALTER TABLE ONLY public.zadania
    ADD CONSTRAINT zadania_pkey PRIMARY KEY (id_zadania);
 >   ALTER TABLE ONLY public.zadania DROP CONSTRAINT zadania_pkey;
       public                 postgres    false    238            �           2620    17866    otwarcia ocena_do_partii    TRIGGER        CREATE TRIGGER ocena_do_partii AFTER UPDATE ON public.otwarcia FOR EACH ROW EXECUTE FUNCTION public.ocena_do_partii_trigger();
 1   DROP TRIGGER ocena_do_partii ON public.otwarcia;
       public               postgres    false    243    227            �           2620    17868 )   gracze stworzenie_konta_po_dodaniu_gracza    TRIGGER     �   CREATE TRIGGER stworzenie_konta_po_dodaniu_gracza AFTER INSERT ON public.gracze FOR EACH ROW EXECUTE FUNCTION public.stworzenie_konta_po_dodaniu_gracza();
 B   DROP TRIGGER stworzenie_konta_po_dodaniu_gracza ON public.gracze;
       public               postgres    false    259    220            �           2620    17867    partie updatepopularneotwarcia    TRIGGER     �   CREATE TRIGGER updatepopularneotwarcia AFTER INSERT ON public.partie FOR EACH ROW EXECUTE FUNCTION public.updatepopularneotwarcia_trigger();
 7   DROP TRIGGER updatepopularneotwarcia ON public.partie;
       public               postgres    false    260    229            �           2606    17778    gracze fk_gracze_konta    FK CONSTRAINT     �   ALTER TABLE ONLY public.gracze
    ADD CONSTRAINT fk_gracze_konta FOREIGN KEY (id_konta) REFERENCES public.konta(id_konta) ON UPDATE RESTRICT ON DELETE RESTRICT;
 @   ALTER TABLE ONLY public.gracze DROP CONSTRAINT fk_gracze_konta;
       public               postgres    false    220    4731    222            �           2606    17783    gracze fk_gracze_trenerzy    FK CONSTRAINT     �   ALTER TABLE ONLY public.gracze
    ADD CONSTRAINT fk_gracze_trenerzy FOREIGN KEY (id_trenera) REFERENCES public.trenerzy(id_trenera) ON UPDATE CASCADE ON DELETE SET NULL;
 C   ALTER TABLE ONLY public.gracze DROP CONSTRAINT fk_gracze_trenerzy;
       public               postgres    false    234    4749    220            �           2606    17788    konta fk_konta_gracze    FK CONSTRAINT     �   ALTER TABLE ONLY public.konta
    ADD CONSTRAINT fk_konta_gracze FOREIGN KEY (id_gracz) REFERENCES public.gracze(id_gracz) ON UPDATE CASCADE ON DELETE CASCADE;
 ?   ALTER TABLE ONLY public.konta DROP CONSTRAINT fk_konta_gracze;
       public               postgres    false    4727    220    222            �           2606    17793 $   konta_zadania fk_konta_zadania_konta    FK CONSTRAINT     �   ALTER TABLE ONLY public.konta_zadania
    ADD CONSTRAINT fk_konta_zadania_konta FOREIGN KEY (id_konta) REFERENCES public.konta(id_konta) ON DELETE CASCADE;
 N   ALTER TABLE ONLY public.konta_zadania DROP CONSTRAINT fk_konta_zadania_konta;
       public               postgres    false    222    223    4731            �           2606    17798 &   konta_zadania fk_konta_zadania_zadania    FK CONSTRAINT     �   ALTER TABLE ONLY public.konta_zadania
    ADD CONSTRAINT fk_konta_zadania_zadania FOREIGN KEY (id_zadania) REFERENCES public.zadania(id_zadania) ON DELETE CASCADE;
 P   ALTER TABLE ONLY public.konta_zadania DROP CONSTRAINT fk_konta_zadania_zadania;
       public               postgres    false    223    4753    238            �           2606    17808    oceny fk_oceny_konta    FK CONSTRAINT     �   ALTER TABLE ONLY public.oceny
    ADD CONSTRAINT fk_oceny_konta FOREIGN KEY (id_konta) REFERENCES public.konta(id_konta) ON DELETE CASCADE;
 >   ALTER TABLE ONLY public.oceny DROP CONSTRAINT fk_oceny_konta;
       public               postgres    false    4731    222    225            �           2606    17803    oceny fk_oceny_partie    FK CONSTRAINT     �   ALTER TABLE ONLY public.oceny
    ADD CONSTRAINT fk_oceny_partie FOREIGN KEY (id_partii) REFERENCES public.partie(id_partii) ON DELETE CASCADE;
 ?   ALTER TABLE ONLY public.oceny DROP CONSTRAINT fk_oceny_partie;
       public               postgres    false    4739    225    229            �           2606    17813    partie fk_partie_gracz_bialy    FK CONSTRAINT     �   ALTER TABLE ONLY public.partie
    ADD CONSTRAINT fk_partie_gracz_bialy FOREIGN KEY (id_gracz_bialy) REFERENCES public.gracze(id_gracz) ON DELETE CASCADE;
 F   ALTER TABLE ONLY public.partie DROP CONSTRAINT fk_partie_gracz_bialy;
       public               postgres    false    220    4727    229            �           2606    17818    partie fk_partie_gracz_czarny    FK CONSTRAINT     �   ALTER TABLE ONLY public.partie
    ADD CONSTRAINT fk_partie_gracz_czarny FOREIGN KEY (id_gracz_czarny) REFERENCES public.gracze(id_gracz) ON DELETE CASCADE;
 G   ALTER TABLE ONLY public.partie DROP CONSTRAINT fk_partie_gracz_czarny;
       public               postgres    false    220    4727    229            �           2606    17823    partie fk_partie_otwarcia    FK CONSTRAINT     �   ALTER TABLE ONLY public.partie
    ADD CONSTRAINT fk_partie_otwarcia FOREIGN KEY (id_otwarcia) REFERENCES public.otwarcia(id_otwarcia) ON DELETE SET NULL;
 C   ALTER TABLE ONLY public.partie DROP CONSTRAINT fk_partie_otwarcia;
       public               postgres    false    227    4737    229            �           2606    17828    partie fk_partie_sedziowie    FK CONSTRAINT     �   ALTER TABLE ONLY public.partie
    ADD CONSTRAINT fk_partie_sedziowie FOREIGN KEY (id_sedziego) REFERENCES public.sedziowie(id_sedziego) ON DELETE CASCADE;
 D   ALTER TABLE ONLY public.partie DROP CONSTRAINT fk_partie_sedziowie;
       public               postgres    false    232    229    4745            �           2606    17838 )   partie_turnieje fk_partie_turnieje_partie    FK CONSTRAINT     �   ALTER TABLE ONLY public.partie_turnieje
    ADD CONSTRAINT fk_partie_turnieje_partie FOREIGN KEY (id_partii) REFERENCES public.partie(id_partii) ON DELETE CASCADE;
 S   ALTER TABLE ONLY public.partie_turnieje DROP CONSTRAINT fk_partie_turnieje_partie;
       public               postgres    false    4739    229    230            �           2606    17833 +   partie_turnieje fk_partie_turnieje_turnieje    FK CONSTRAINT     �   ALTER TABLE ONLY public.partie_turnieje
    ADD CONSTRAINT fk_partie_turnieje_turnieje FOREIGN KEY (id_turnieju) REFERENCES public.turnieje(id_turnieju) ON DELETE CASCADE;
 U   ALTER TABLE ONLY public.partie_turnieje DROP CONSTRAINT fk_partie_turnieje_turnieje;
       public               postgres    false    236    4751    230            J           0    17849    wyniki_turniejow    MATERIALIZED VIEW DATA     3   REFRESH MATERIALIZED VIEW public.wyniki_turniejow;
          public               postgres    false    240    4940            7   �  x�]�An�0E��S�*HQ��e� n�Z(��x3�U��"�!�F��#�z��&�����'K���}�V�� ��c������W��Y�0�^H������pD ��<�)3nXA�H�?�����f��W��L��{�C�a���?�,����m��m�	'�"�
��л��-텇�^�x}�2�3a�&߰K(�X���iL⒫x��,\2J>[O���~���'eQ�H]N�	23|�m�}C�\ho�8t���z9EM�bB�%sKķ�������K.���!x3��T���j���{�ZLe4��T%U/$uIc�P��6�u���)���]*W򂉂��Q�����쿃�?A����@$�;��}����p>��/)�L�(Y3��p�pn��Ɲ��ow�)���Eq�D	��|=B�G��l�1�)δF      9   t  x�U�Ir�0E��]�,;$5&i(���#�B������K��;]�-����t%QeRgJƒ�4�75]Vr�خ�<�Va&m��:�\������ҙ,3���h�4_�D�.��o�5К�~۽#���Z�.E	%D��B͛\ j�gl�P�J(�T��1�&f(���L�沢����4�y�W���Ӑ
��/���.C�x��#c[����j�a��҆���x�8�w���J��xd�P��s	���Fs�z�2��y�й��ڭ�����&q���7Z��r�U��ƂV�R���o�X�g#�F+l��H���M�ɏ��������+�\�>)-��}�}ڏ�f3���.�!~i���      :   �   x�%��D!е)f���ts��"�4�ԇH�6c�(ף�.7N��9ă���/�M]I�L�X�u�����\9v_���&g�2�h9#�4��B�{?Q~��R�-�u�����`E�!�^�����&j      <   I  x�-�Mr�0���)�}�H�9A6Ƹ�Pl��a�@]t�UW�!��deY���gY�	)|��k��Z-$��`��P�#�۹Q$$�P@���X�6̶����q��:�}g�?�isi���*2���g����O��-���QS�(�'����A��r������3)#�]��1�M�M�܇6�wVHg'�[dB�U(I�C�l=ho�Jg���f�ʖn����i�L�)H���eoq[VC/�%�2���l�K��k�A�T_�gP� �x�č�c�s�|�
�?b�`��#��a[KB�9�PV�$ڕ|�s��>��l�f      >   �   x�}�Mn1�יS�T���,YuA%P�vc����(	�2��z.V�� UH�~����Zm��	!��8{�B�`���;�&5mfj������]�8W[�"����(pQ�x�F"�K��~ot���L� ���~����=ҧN���~���>��s�4�/��t=U�������ֺ.��2X1�rzV+g�W4W��x��p��d�0_��*�g�3⏇�i~�G��      @     x��T�n�0<����ª��u�8?ЋEJBР(��|}g�2U%J�̃wvfv��,���s���H{jH�*:5zeju�_P�V�U����Ur��D�M�Z��>4�!G��ϧ�ߗ��k$m�������5�te��8�X��R6S�����y07��Z��=�q;@��gA� �����A�x��P��2����P����w�������ϭ�`as�����7��B ��?��B���U-u��]��[�h��r{�����T
21�i���e�봒��]�BIxNADu�5�hPZ����nG3:�9>�ydq��q��ˬ�]$��d��J��A��p�-;���C����fl�<s��,w>�S�6�؎\(-��?����"����2��#1s�K<bq`1���P�Y�Ĕ�ޛ�a��Hy��~�ӽY,�G���۲���'�r�$y�N�-r`A������$[F˃b׭�M�T �{����H�����׫K���a�q�/�:�Lñ�-�����hyC~�UU��b�      A   5   x���  �e#ؚt���� � �P���QM�I�@<k��cڎ���P      C   �   x�M�1�0Eg�0H���]@�����f�Z)i��5��Zq/XXl�~��ԅt�=Ő�nP�9�JB�M(8�<-Ϫm��|���})�B�(�(v����5l��+�����#U��+�PfH������J�ٰ�8�3��X�i������j|?�Y��:c�����"(<      E   �   x�%�A�0E�3�!���j4�5.��@��M�!����'���g��7���i������	�Y1.�t��xU7��6�#���*/Al�ә�+8�7������I��-�9��*}'���U��������)��io;456p%��� a���h���"� ��;�      G   k   x�3�qqTqu�Qp�pV0202�,�,.I�U��?�9���ӿ�<����ˈ�7����*�(�ptRyfbI"P��LGqUybVrbQqv&gTbnv^f*P_� �$$`      I   4  x�5�ɑ%9C���L$m���v��}��ħH$X1�|#~9*���jD�{�)��ȵ�^cV�ǎ���s��;����(@���9�2j�R��q�2ɮ,�ƹWy�rF�B�hݳA2�]�I2_��m6��9ɼ�j��� \n��3���5'H��=��^r̥GU��4�<_�t�/�*o%F��J\w�W��b ��N��D#ƕ<<����B����Q�>0u��@���Bb?��Bt&��1hqU��8fэ����"H����$����7�JmŬ$Xt�TV���]��FP�a��Q[3^g�V�u������AŠ�q-�!��_�=y�W��N�2��>�	�S
���)1e��:$�$\���:�E6���J�٩LM�V��j�׋ʖU�+y��S��H�2k�?�0����:+>o�%l��z��Kvֶ`y�,cM�clb��FM[��~q�p0����X�X��w>Wa�u������S���O�<�-����.oa`�j3Ɠ.�)c���+C�t�����a�}���]`�wno�Y��.+��6F�KழEB}O)�Y=�wݴ��a�G���2�#�5:.ƻ~R��
gn]C���~�2����F���xM2�k�z�~Ǐ[;G���̵�f�L�u�n��d����)C����㺦�F�W�}|b�o-���>�b ���\���"��P��j�-��4?v�>s�Ƚ��]Ȳ[Z����������4�Ϲ�C�Ӕ��i��B¨��6�����p/�5������>J�/�3�f%��0��r��\���������     