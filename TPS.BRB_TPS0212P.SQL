CREATE OR REPLACE PROCEDURE TPS.BRB_TPS0212P

 (P_JOB         IN Number
 ,P_AFFAIRE     IN Varchar2 
 ,P_BU          IN Varchar2
 ,P_CLIENT      IN Varchar2 
 ,P_DETAIL      IN Varchar2
 ,P_TYPE_G      IN Varchar2
 )
 IS



/**************************************************************************************************
Auteur   : m_Elasri
Date     : 11 / 07 / 2019
Fonction : EXTRACTION des états Commerciaux
***************************************************************************************************/
Cursor C_instance is
       SELECT name
       FROM      sys.v_$database;

Cursor C_Param is
       SELECT repertoire,separateur,suffixe_dat,suffixe_log,base_script
       FROM      ADM_INT_PARAM;

c1 sys_refcursor;

v_amo_cache varchar2(10) ;

WParam          C_Param%Rowtype;
Wfile1          UTL_FILE.FILE_TYPE;
Wfile2          UTL_FILE.FILE_TYPE;
Wnbenr          Number := 0;
Winstance       Varchar2(30);
v_requete       VARCHAR2(15000) ;

TYPE t_sample IS RECORD
      (
        date_histo                  varchar2(100),
        affaire                     varchar2(100),
        otp                         varchar2(800),
        client                      varchar2(100),
        bu                          varchar2(100),
        commercial                  varchar2(100),
        designation                 varchar2(800),
        type_produit                varchar2(100),
        vehicule                    varchar2(100),
        date_dms                    varchar2(20),
        type_g                      varchar2(100),
        type                        varchar(5) := NULL ,
        vente_a_amortir             varchar2(100),
        quantite_prev               varchar2(100),
        qte_tot_amo                 varchar2(100),
        amorti_du_mois              varchar2(100),
        nombre_mois                 varchar2(100),
         num_chrono                 varchar2(100),
        amo_cache                   varchar2(100),
        date_deb_amo_reel           varchar2(100),
        reste_a_amortir             varchar2(100),
        vente_amortie_apres_reneg   varchar2(100),
        REATRD_COMBLE              varchar2(50),
        surplus_report              varchar2(50),
        reste_a_amortir_apres_reneg varchar2(100),
        id                          number,
        num_lancement_plm           number, 
        eotp                        varchar2(50),
        qte_prev                    number ,
        part_amo                    number ,
        gestionnaire                varchar2(50), 
        l_designation               varchar2(100)
      );


v_row       t_sample ;
v_row2      t_sample ;
v_row3      t_sample ;
v_SUM       t_sample ;
 

v_dateHisto VARCHAR2(20) ;
v_n_ligne   number := 0 ;



Function GenerateQuery( F_DETAIL IN VARCHAR2 , F_AFFAIRE IN VARCHAR2 , F_BU IN VARCHAR2 , F_client   IN VARCHAR2 , F_type_g IN VARCHAR2 ) RETURN VARCHAR2 IS
-- (P_DETAIL ,P_AFFAIRE ,P_BU,P_CLIENT , P_TYPE_G );

    v_columns               varchar2(1500) := '';
    v_gpby_statement        varchar2(400) := '';
    wh_typeGes              varchar2(300) :='';


BEGIN
    if TRIM(F_DETAIL) = 'O' OR TRIM(F_DETAIL) = 'o' then
        v_columns    := ' 
                        ''DET'' AS TYPE ,
                        vente_a_amortir,
                        quantite_prev,
                        qt_tot_amo ,
                        amorti_du_mois,
                        nombre_mois ,
                        num_chrono,
                        amo_cache ,'
                         ||CASE TRIM(P_DETAIL) WHEN   'O'  THEN ' to_char(date_deb_amo_reel,''DD/MM/YYYY'') date_deb_amo_reel ,'  WHEN  'N'  THEN ' to_char(debut_amort_theo,''DD/MM/YYYY'') date_deb_amo_reel ,'  END|| 
                        'reste_a_amortir,
                        vente_amortie_apres_reneg ,
                        REATRD_COMBLE , 
                        SURPLUS_REPORT ,
                        reste_a_amortir_apres_reneg ,
                        ID ,
                        num_lancement_plm  , 
                        eotp , 
                        Qte_prev ,
                        Part_amo ,
                        Gestionnaire , 
                        l_DESIGNATION
                        ';
                                                                        
        if TRIM(F_type_g) = 'TOUS' then
             wh_typeGes:= ' AND (type_g LIKE ''%FIN%'' OR type_g LIKE ''%PPA%'' OR type_g LIKE ''%BLINK%'' OR type_g LIKE ''%DIVERS%'') '; 
        elsif TRIM(F_type_g) = 'PPA' then               
             wh_typeGes := ' AND (type_g LIKE ''%PPA%'' OR type_g LIKE ''%FIN%'' ) ';           
        else                                            
             wh_typeGes := ' AND type_g LIKE ''%'|| F_type_g || '%'' ';             
        end if;                                    
                                    
    elsif TRIM(F_DETAIL) = 'N' OR TRIM(F_DETAIL) = 'n' then    
             v_columns      := ' 
                                ''TOT'' AS TYPE ,
                                sum(vente_a_amortir) vente_a_amortir,
                                null quantite_prev,
                                null qt_tot_amo,
                                sum(amorti_du_mois) amorti_du_mois,
                                max(nombre_mois) nombre_mois,
                                 null  num_chrono,
                               ''TOTAL''      amo_cache ,'
                               ||CASE TRIM(P_DETAIL) WHEN 'O'  THEN 'min(to_char(date_deb_amo_reel,''DD/MM/YYYY'')) date_deb_amo_reel ,'   WHEN  'N'  THEN ' min(to_char(debut_amort_theo,''DD/MM/YYYY'')) date_deb_amo_reel  ,' END||   
                                'sum(reste_a_amortir) reste_a_amortir,
                                sum(vente_amortie_apres_reneg) vente_amortie_apres_reneg,
                                sum(REATRD_COMBLE)      REATRD_COMBLE , 
                                sum(SURPLUS_REPORT)     SURPLUS_REPORT ,
                                sum(reste_a_amortir_apres_reneg) reste_a_amortir_apres_reneg ,
                                null    ID ,
                                null   num_lancement_plm  , 
                                null    eotp , 
                                null    Qte_prev ,
                                null     Part_amo ,
                                null   Gestionnaire ,
                                null  l_DESIGNATION                                    
                                ';
                                           
                                     v_gpby_statement := '    group by bu,client,affaire,otp,commercial,designation,date_histo,type_produit,vehicule,date_dms ';

                                
                                if TRIM(F_type_g) = 'TOUS' then
                                     wh_typeGes:= ' AND (type_g LIKE ''%FIN%'' OR type_g LIKE ''%PPA%'' OR type_g LIKE ''%BLINK%'' OR type_g LIKE ''%DIVERS%'') '; 
                                elsif TRIM(F_type_g)  =  'PPA'  then               
                                     wh_typeGes := '  AND (type_g LIKE ''%PPA%'' OR type_g LIKE ''%FIN%'')' ;           
                                else                                            
                                     wh_typeGes := ' AND type_g LIKE ''%'|| F_type_g || '%'' ';             
                                end if;   
 
    end if ;
    
 return ' select 
        to_char(date_histo,''DD/MM/YYYY'') date_histo,
        affaire,
        OTP,
        client,
        bu,
        commercial,
        designation,
        TYPE_PRODUIT,
        VEHICULE ,
        to_char(DATE_DMS,''dd/mm/yyyy'') DATE_DMS ,
        ''''  type_g,
        '||v_columns || ' 
        from
            (
            SELECT
                    (select last_day(max(date_histo)) from amort_vente_rea)                                                                                             date_histo,
                    l.affaire                                                                                                                                           affaire,
                    A.OTP                                                                                                                                               otp,
                    a.bu                                                                                                                                                bu,
                    a.designation                                                                                                                                       designation,
                    l.commercial                                                                                                                                        commercial,
                    a.client                                                                                                                                            client,
                    replace(a.observation,chr(10),'' '')                                                                                                                observation,
                    a.vehicule                                                                                                                                          vehicule,
                    l.amo_cache                                                                                                                                         amo_cache,
                    l.type_g                                                                                                                                            type_g,
                    l.retard_dms                                                                                                                                        retard_dms,
                    a.date_dms                                                                                                                                          date_dms,
                    d.date_deb_amorti                                                                                                                                   debut_amort_theo,
                    l.id                                                                                                                                                id_lanc,
                    l.type_budget                                                                                                                                       type_budget,
                    L.EOTP                                                                                                                                              eotp,
                    decode(l.type_g, ''FIN'', ''PPA'', l.type_g)                                                                                                        type_gestionnaire,
                    l.gestionnaire                                                                                                                                      gestionnaire,
                    L.CALCUL_PS                                                                                                                                         calcul_ps,
                    L.PFAE_COMPTA                                                                                                                                       fae_compta,
                    L.SOP_DMS                                                                                                                                           sop,
                    l.num_chrono                                                                                                                                        num_chrono,
                    decode(l.type_budget, ''RETROCESSION AMORTISSEMENT'', -1 * d.bdg_vente_amortie_out,d.bdg_vente_amortie_out)                                         vente_a_amortir,
                    decode(l.type_budget, ''RETROCESSION AMORTISSEMENT'', -1 * d.bdg_vente_amort_sfi,d.bdg_vente_amort_sfi)                                             vente_amort_ssfi,
                    d.quantite                                                                                                                                          quantite_prev,
                    d.nombre_mois                                                                                                                                       nombre_mois,
                    round(d.bdg_vente_amortie_out / nvl(d.quantite,1),2)                                                                                                prix_piece,
                    qt.date_db_amo                                                                                                                                      date_deb_amo_reel,
                    qt.qte_tot                                                                                                                                          qt_tot_amo,
                    round(d.bdg_vente_amortie_out - d.bdg_vente_amortie_out / nvl(d.quantite,1) * qt.qte_tot,2)                                                         reste_a_amortir,
                    decode(nvl(vt.vente_amo_nego,-0.99), -0.99,round(d.bdg_vente_amortie_out / nvl(d.quantite,1) * qt.qte_tot,2) ,D.BDG_VENTE_AMORTIE_OUT - vt.vente_amo_nego)           vente_amortie_apres_reneg,
                    decode(nvl(vt.vente_amo_nego,-0.99), -0.99, round(d.bdg_vente_amortie_out - d.bdg_vente_amortie_out / nvl(d.quantite,1) * qt.qte_tot,2),nvl(vt.vente_amo_nego,0) )   reste_a_amortir_apres_reneg,
                    round(qte_der.qte * d.bdg_vente_amortie_out / nvl(d.quantite,1),2)                                                                                  amorti_du_mois,
                    L.CLOS_FIN                                                                                                                                          clo_fin,
                    bai.baisse                                                                                                                                          baisse ,
                    vt.REATRD_COMBLE , 
                    vt.SURPLUS_REPORT ,
                    a.TYPE_PRODUIT ,
                    l.ID ,
                    l.num_lancement_plm  , 
                    QT.qte_tot Qte_prev ,
                    d.bdg_vente_amortie_out/DECODE(nvl(d.quantite,0),0,1,d.quantite) as Part_amo ,
                    L.DESIGNATION l_DESIGNATION
            from affaire a,
                lancement l,
                lancement_detail d,
                type_budget t,
                V_AFFAIRE_GRP_SOC_VALIDE g,
                (select lancement, vente_amo_rea, vente_amo_nego , REATRD_COMBLE , SURPLUS_REPORT  
                from amort_vente_rea v
                where v.date_histo = (select max(v1.date_histo) from amort_vente_rea v1 where v1.lancement = v.lancement)
                ) vt,
                (select lancement, sum(quantite) qte from amortissement_piece
                where an_mois >= (select add_months(last_day(max(date_histo))+1,-1) from amort_vente_rea)
                and an_mois  <= (select last_day(max(date_histo)) dernier_jour from amort_vente_rea)
                group by lancement) qte_der,
                (select lancement,min(an_mois) date_db_amo,sum(quantite) qte_tot from amortissement_piece
                group by lancement) qt,
                (select lancement, max(num_baisse_prix) baisse from ref_piece_amortie
                group by lancement) bai
            WHERE l.affaire = a.affaire
            AND g.affaire(+) = l.affaire
            and l.id = D.LANCEMENT
            and t.CODE = l.TYPE_BUDGET
            and d.DATE_DEBUT = (select max(d1.date_debut) from lancement_detail d1 where d1.lancement = d.lancement)
            and nvl(d.QUANTITE,0) > 0
            and d.bdg_vente_amortie_out <> 0
            and l.clos_fin = ''N''
            and l.fonction not in (''PPA'',''PPP'')
            and l.id = vt.lancement(+)
            and l.id = qte_der.lancement(+)
            and l.id = qt.lancement(+)
            and l.id = bai.lancement(+)
            and l.type_budget <> ''RETROCESSION AMORTISSEMENT''
            and l.type_budget <> ''COMPENS AMORTIS / FACTURE''
            and l.type_budget <> ''COMPENSATION AMORTISSEMENT''
            and l.type_budget <> ''REVISION AMORTISSEMENT'')
            where affaire LIKE ''%' || F_AFFAIRE || '%'' 
            AND client LIKE ''%' || F_client || '%'' 
            AND bu LIKE ''%' || F_BU ||  '%'''  || wh_typeGes
            || v_gpby_statement ;
END;


procedure ecr(zchar varchar2) is
    Begin
        if zchar = 'CRLF' then
            BRB$FILE.ADD_DATA (Wfile1,chr(13)||chr(10),0);
            UTL_FILE.FFLUSH (Wfile1);
        else
            BRB$FILE.ADD_DATA (Wfile1,zchar,0,';');
        end if;
    End;

 function PVL_STRCMP(a in varchar2, b in varchar2)
return pls_integer as
    begin
      if a is null and b is null then
        return 1;
      end if;

      if TRIM(a) =  TRIM(b) then
        return 1;
      end if;
      
      return 0;
    end;
Begin
     Open  C_instance;
     Fetch C_instance into Winstance;
     Close C_Instance;

     Open  C_Param;
     Fetch C_Param into WParam;
     Close C_Param;

     Wfile1 := BRB$FILE.Open_File(WParam.repertoire,'tps0212_' || P_Job || '.' || WParam.suffixe_dat);
     Wfile2 := BRB$FILE.Open_File(WParam.repertoire,'tps0212_' || P_Job || '.' || WParam.suffixe_log);

     BRB$FILE.ADD_LINE(Wfile2,'***********************************************************');
     BRB$FILE.ADD_LINE(Wfile2,'* EXTRACTION des états Commerciaux                           *');
     BRB$FILE.ADD_LINE(Wfile2,'***********************************************************');

     BRB$FILE.ADD_LINE(Wfile2,'Instance   : ' || Winstance);
     BRB$FILE.ADD_LINE(Wfile2,'Commencé à : ' || to_char(sysdate,'DD/MM/YYYY HH24:MI'));
     
     

    IF TRIM(P_DETAIL) = 'O' OR TRIM(P_DETAIL) = 'o' then    -- AVEC DETAIL 
            ecr ('##H;BU;CLIENT;COMMERCIAL;Num_aff°; OTP ;AFFAIRE;TYPE PRODUIT;VEHICULE ;ID;Num lanc;Num EOTP;Designation ;Chrono ;Type G   ;Gestionnaire ;SOP(DMS);Qte prev ; Part amo  ; AMO CACHé;MONTANT A AMORTIR ;DUREE PREVUE ; DATE DEBUT REELLE  ;  RESTE A AMORTIR   ;  MONTANT AMORTI APRES RENGO ; RETARD COMBLE ;  SURPLUS REPORT;  RESTE A AMORTIR APRES RENEGO');
            ecr('CRLF');
     ELSIF TRIM(P_DETAIL) = 'N' OR TRIM(P_DETAIL) = 'n' THEN --SANS DETAIL
            ecr ('##H;BU;CLIENT;COMMERCIAL;Num_aff°; OTP ;AFFAIRE;TYPE PRODUIT;VEHICULE  ;Gestionnaire ;SOP(DMS)  ; AMO CACHé;MONTANT A AMORTIR ;DUREE PREVUE ; DATE DEBUT REELLE  ;  RESTE A AMORTIR   ; MONTANT AMORTI APRES RENGO ; RETARD COMBLE ;  SURPLUS REPORT;  RESTE A AMORTIR APRES RENEGO');
            ecr('CRLF');
     END IF ;




                 ecr ('##L'); -- LONGEUR DES COLONNES
                 ecr ('25');  -- Longeur  BU            ( 1 )
                 ecr ('25');  -- Longeur  CLIENT        ( 2 )
                 ecr ('25');  -- Longeur  CCOMMERCIAL   ( 3 )
                 ecr ('25');  -- Longeur  Num_aff°      ( 4)
                 
                 ecr ('40'); -- Longeur  OTP            ( 5 )
                 ecr ('70'); -- Longeur  AFFAIRE        ( 6 )
                 ecr ('20'); -- TYPE PRODUIT            ( 7 )
                 ecr ('20'); -- VEHICULE                ( 8 )
                 
               IF TRIM(P_DETAIL) = 'O' OR TRIM(P_DETAIL) = 'o' then               
                     ecr ('20'); -- Longeur  ID             ( 9 )
                     ecr ('20'); -- Longeur  Num lanc       ( 10)
                     ecr ('20'); -- Longeur  Num EOTP       ( 11)
                     ecr ('20'); -- Longeur  Designation    ( 12 )
                     ecr ('20'); -- Longeur  Chrono         ( 13)
                     ecr ('20'); -- Longeur  Type G         ( 14 )
                 END IF ;
                 ecr ('20'); -- Longeur  Gestionnaire   ( 15 )
                 ecr ('20'); -- Longeur  SOP            ( 16 )
                  IF TRIM(P_DETAIL) = 'O' OR TRIM(P_DETAIL) = 'o' then               
                         ecr ('20'); -- Longeur  Qte prev       ( 17 )
                         ecr ('20'); -- Longeur  Part amo       ( 18 )
                 END IF ;


                 ecr ('25'); -- Longeur AMO CACHé       ( 19 )
                 ecr ('25'); -- Longeur  MONTANT A AMORTIR              ( 20 )
                 
                 ecr ('25'); -- Longeur  DUREE PREVUE                   ( 21)
                 ecr ('25'); -- Longeur  DATE DEBUT REELLE              ( 22 )
                 ecr ('25'); -- Longeur  RESTE A AMORTIR                ( 23 )
                 ecr ('25'); -- Longeur  MONTANT A AMORTIR APRES RENEGO ( 24 )
                 ecr ('25'); -- Longeur RETARD COMBLE                   ( 25)
                 ecr ('25'); -- Longeur  SURPLUS REPORT                 ( 26 )
                 ecr ('25'); -- Longeur  RESTE A AMORTIR APRES RENEGO   ( 27)

                 ecr('CRLF');

                 ecr ('##AL'); -- Alignement des colonne : [ GAUCHE : 1 ] [CENTER : 2 ] [ Droit : 3 ]
                  
                 ecr ('2');  -- Longeur  BU                             ( 1 )
                 ecr ('2');  -- Longeur  CLIENT                         ( 2 )
                 ecr ('2'); -- Longeur  CCOMMERCIAL                     ( 3 )
                 ecr ('2'); -- Longeur  Num_aff°                        ( 4)
                 
                 ecr ('2'); -- Longeur  OTP                             ( 5 )
                 ecr ('2'); -- Longeur  AFFAIRE                         ( 6 )
                 ecr ('2'); -- TYPE PRODUIT                             ( 7 )
                 ecr ('2'); -- VEHICULE                                 ( 8 )
                   IF TRIM(P_DETAIL) = 'O' OR TRIM(P_DETAIL) = 'o' then               
                             ecr ('2'); -- Longeur  ID                              ( 9 )
                             ecr ('2'); -- Longeur  Num lanc                        ( 10)
                             ecr ('2'); -- Longeur  Num EOTP                        ( 11)
                             ecr ('2'); -- Longeur  Designation                     ( 12 )
                             ecr ('2'); -- Longeur  Chrono                          ( 13)
                             ecr ('2'); -- Longeur  Type G                          ( 14 )
                     END IF ;


                 ecr ('2'); -- Longeur  Gestionnaire                    ( 15 )
                 ecr ('2'); -- Longeur  SOP                             ( 16)
                 
                 IF TRIM(P_DETAIL) = 'O' OR TRIM(P_DETAIL) = 'o' then               
                         ecr ('2'); -- Longeur  Qte prev                        ( 17 )
                         ecr ('2'); -- Longeur  Part amo                        ( 18 )
                 END IF ;


                 ecr ('2'); -- Longeur AMO CACHé                        ( 19 )
                 ecr ('2'); -- Longeur  MONTANT A AMORTIR               ( 20)
                 
                 ecr ('2'); -- Longeur  DUREE PREVUE                    ( 21)
                 ecr ('2'); -- Longeur  DATE DEBUT REELLE               ( 22 )
                 ecr ('2'); -- Longeur  RESTE A AMORTIR                 ( 23 )
                 ecr ('2'); -- Longeur  MONTANT A AMORTIR APRES RENEGO  ( 24 )
                 ecr ('2'); -- Longeur RETARD COMBLE                    ( 25)
                 ecr ('2'); -- Longeur  SURPLUS REPORT                  ( 26 )
                 ecr ('2'); -- Longeur  RESTE A AMORTIR APRES RENEGO    ( 27)
                 ecr('CRLF');
                 
                 
                ecr ('##COND'); --on change la couleur de la Cellule de la colonne  10 en  ROUGE RGB('255,0,0') SI EGAL à 'O'
                ecr ( CASE TRIM(P_DETAIL)
                                                                     WHEN 'O' THEN '19'
                                                                     WHEN 'N' THEN '11'
                                                                     ELSE ''  END
                         );     -- LA COLONNE
                ecr ('O');      -- LA CONDITION : LA VALEUR DE LA CELLULE DOIT ETRE EGAL à 'O'
                ecr('255');     -- LA COULEUR EN RGB PAR DEFAULT EN ROUGE
                ecr('0');       -- LA COULEUR EN RGB PAR DEFAULT EN ROUGE
                ecr('0');       -- LA COULEUR EN RGB PAR DEFAULT EN ROUGE
                ecr('CRLF'); -- FIN    
       
     
     
         BRB$FILE.ADD_LINE(Wfile2 , GenerateQuery('N' ,P_AFFAIRE ,P_BU,P_CLIENT , P_TYPE_G ) || '      UNION      ' || GenerateQuery('O' ,P_AFFAIRE ,P_BU,P_CLIENT , P_TYPE_G ) ||'       ORDER  BY BU , CLIENT , commercial , affaire , OTP , designation ,TYPE_PRODUIT , VEHICULE , DATE_DMS , TYPE'  );

            
         
       -- Ecrire les Lignes du fichier excel
                        BEGIN
                              open c1 for  GenerateQuery('N' ,P_AFFAIRE ,P_BU,P_CLIENT , P_TYPE_G ) || '      UNION  ALL     ' || GenerateQuery('O' ,P_AFFAIRE ,P_BU,P_CLIENT , P_TYPE_G ) ||'       ORDER  BY BU , CLIENT , commercial , affaire , OTP , designation ,TYPE_PRODUIT , VEHICULE , DATE_DMS , TYPE' ; 
                                  LOOP
                                       fetch c1 into v_row ;
                                           EXIT WHEN c1%NOTFOUND ;                                            
                                                        IF PVL_STRCMP(  P_DETAIL    ,'O') = 1 THEN                                                                   
                                                                    IF PVL_STRCMP(v_row.TYPE,'DET') = 1 THEN                                                    
                                                                            ecr('##R'                              );
                                                                    ELSIF PVL_STRCMP(v_row.TYPE,'TOT') = 1 THEN
                                                                            ecr ('##TOTAL');
                                                                            v_SUM.vente_a_amortir                           :=  nvl(v_SUM.vente_a_amortir,0) +  nvl(v_row.vente_a_amortir,0) ;
                                                                            v_SUM.reste_a_amortir                            :=  nvl(v_SUM.reste_a_amortir,0)   +  nvl(v_row.reste_a_amortir,0)    ;
                                                                            v_SUM.vente_amortie_apres_reneg   :=  nvl(v_SUM.vente_amortie_apres_reneg,0)  +  nvl(v_row.vente_amortie_apres_reneg,0)  ;
                                                                            v_SUM.REATRD_COMBLE                          :=  nvl(v_SUM.REATRD_COMBLE,0) +  nvl(v_row.REATRD_COMBLE,0) ;
                                                                            v_SUM.SURPLUS_REPORT                         :=  nvl(v_SUM.SURPLUS_REPORT,0) +  nvl(v_row.SURPLUS_REPORT,0) ;
                                                                            v_SUM.reste_a_amortir_apres_reneg :=  nvl(v_SUM.reste_a_amortir_apres_reneg,0) +  nvl(v_row.reste_a_amortir_apres_reneg,0) ;
                                                                    END IF ;
                                                                    ecr(v_row.bu                           );
                                                                    ecr(v_row.client                       );
                                                                    ecr(v_row.commercial                   );
                                                                    ecr(v_row.affaire                      );
                                                                    ecr(v_row.OTP                          );
                                                                    ecr( v_row.designation                 );
                                                                    ecr( v_row.TYPE_PRODUIT                );
                                                                    ecr( v_row.VEHICULE                    );
                                                                    ecr( v_row.ID                          );
                                                                    ecr( v_row.num_lancement_plm           );
                                                                    ecr( v_row.EOTP                        );
                                                                    ecr( v_row.l_Designation               );
                                                                    ecr( v_row.num_chrono                  );
                                                                    ecr( v_row.type_g                      );
                                                                    ecr( v_row.Gestionnaire                );
                                                                    ecr( v_row.DATE_DMS                    );
                                                                    ecr( v_row.Qte_prev                    );
                                                                    ecr( v_row.Part_amo                    );
                                                                    ecr(v_row.amo_cache                    );
                                                                    ecr(v_row.vente_a_amortir              );
                                                                    ecr(v_row.nombre_mois                  );
                                                                    ecr(v_row.date_deb_amo_reel            );
                                                                    ecr(v_row.reste_a_amortir              );
                                                                    ecr(v_row.vente_amortie_apres_reneg    );
                                                                    ecr(v_row.REATRD_COMBLE                );
                                                                    ecr(v_row. SURPLUS_REPORT              );        
                                                                    ecr(v_row.reste_a_amortir_apres_reneg  );                                                                                 
                                                                    ecr('CRLF');
                                                       ELSIF PVL_STRCMP(  P_DETAIL    ,'N') = 1 THEN
                                                                      IF PVL_STRCMP(v_row.TYPE,'DET') = 1 THEN  
                                                                                    IF    PVL_STRCMP( v_row.amo_cache,'N') = 1 THEN 
                                                                                                     IF v_row2.TYPE  IS NULL THEN 
                                                                                                        v_row2 := v_row;
                                                                                                     ELSE
                                                                                                        v_row2.vente_a_amortir  :=  v_row2.vente_a_amortir +  v_row.vente_a_amortir ;
                                                                                                        v_row2.reste_a_amortir    :=  v_row2.reste_a_amortir   +  v_row.reste_a_amortir    ;
                                                                                                        v_row2.vente_amortie_apres_reneg   :=  v_row2.vente_amortie_apres_reneg  +  v_row.vente_amortie_apres_reneg  ;
                                                                                                        v_row2.REATRD_COMBLE  :=  v_row2.REATRD_COMBLE +  v_row.REATRD_COMBLE;
                                                                                                        v_row2.SURPLUS_REPORT  :=  v_row2.SURPLUS_REPORT+  v_row.SURPLUS_REPORT ;
                                                                                                        v_row2.reste_a_amortir_apres_reneg :=  v_row2.reste_a_amortir_apres_reneg +  v_row.reste_a_amortir_apres_reneg ;
                                                                                                     END IF ; 
                                                                                                     
                                                                                                    v_SUM.vente_a_amortir                           :=  nvl(v_SUM.vente_a_amortir,0)                           +  nvl(v_row.vente_a_amortir,0) ;
                                                                                                    v_SUM.reste_a_amortir                            :=  v_SUM.reste_a_amortir                             +  nvl(v_row.reste_a_amortir,0) ;
                                                                                                    v_SUM.vente_amortie_apres_reneg   :=  nvl(v_SUM.vente_amortie_apres_reneg,0)   +  nvl(v_row.vente_amortie_apres_reneg,0)  ;
                                                                                                    v_SUM.REATRD_COMBLE                          :=  nvl(v_SUM.REATRD_COMBLE,0)                          +  nvl(v_row.REATRD_COMBLE,0) ;
                                                                                                    v_SUM.SURPLUS_REPORT                         :=  nvl(v_SUM.SURPLUS_REPORT,0)                         +  nvl(v_row.SURPLUS_REPORT,0) ;
                                                                                                    v_SUM.reste_a_amortir_apres_reneg :=  nvl(v_SUM.reste_a_amortir_apres_reneg,0) +  nvl(v_row.reste_a_amortir_apres_reneg,0) ;                                                                                       
                                                                                   ELSIF PVL_STRCMP( v_row.amo_cache,'O') = 1 THEN
                                                                                                       IF v_row3.TYPE  IS NULL THEN 
                                                                                                            v_row3 := v_row;
                                                                                                       ELSE
                                                                                                            v_row3.vente_a_amortir  :=  v_row3.vente_a_amortir +  v_row.vente_a_amortir ;
                                                                                                            v_row3.reste_a_amortir    :=  v_row3.reste_a_amortir   +  v_row.reste_a_amortir    ;
                                                                                                            v_row3.vente_amortie_apres_reneg   :=  v_row3.vente_amortie_apres_reneg  +  v_row.vente_amortie_apres_reneg  ;
                                                                                                            v_row3.REATRD_COMBLE  :=  v_row3.REATRD_COMBLE +  v_row.REATRD_COMBLE;
                                                                                                            v_row3.SURPLUS_REPORT  :=  v_row3.SURPLUS_REPORT+  v_row.SURPLUS_REPORT ;
                                                                                                            v_row3.reste_a_amortir_apres_reneg :=  v_row3.reste_a_amortir_apres_reneg +  v_row.reste_a_amortir_apres_reneg ;
                                                                                                       END IF ;              
                                                                                                    v_SUM.vente_a_amortir                           :=  nvl(v_SUM.vente_a_amortir,0) +  nvl(v_row.vente_a_amortir,0) ;
                                                                                                    v_SUM.reste_a_amortir                            :=  v_SUM.reste_a_amortir   +  nvl(v_row.reste_a_amortir,0)    ;
                                                                                                    v_SUM.vente_amortie_apres_reneg   :=  nvl(v_SUM.vente_amortie_apres_reneg,0)  +  nvl(v_row.vente_amortie_apres_reneg,0)  ;
                                                                                                    v_SUM.REATRD_COMBLE                          :=  nvl(v_SUM.REATRD_COMBLE,0) +  nvl(v_row.REATRD_COMBLE,0) ;
                                                                                                    v_SUM.SURPLUS_REPORT                         :=  nvl(v_SUM.SURPLUS_REPORT,0) +  nvl(v_row.SURPLUS_REPORT,0) ;
                                                                                                    v_SUM.reste_a_amortir_apres_reneg :=  nvl(v_SUM.reste_a_amortir_apres_reneg,0) +  nvl(v_row.reste_a_amortir_apres_reneg,0) ;                                                             
                                                                                   END IF;                                 
                                                                      ELSIF PVL_STRCMP(v_row.TYPE,'TOT') = 1 THEN    
                                                                                    IF (v_row2.TYPE IS NOT NULL ) AND (v_row3.TYPE IS NOT NULL) THEN
                                                                                              ecr ('##R');
                                                                                              ecr(v_row2.bu                           );
                                                                                              ecr(v_row2.client                       );
                                                                                              ecr(v_row2.commercial                   );
                                                                                              ecr(v_row2.affaire                      );
                                                                                              ecr(v_row2.OTP                          );
                                                                                              ecr( v_row2.designation                 );
                                                                                              ecr( v_row2.TYPE_PRODUIT                );
                                                                                              ecr( v_row2.VEHICULE                    );
                                                                                              ecr( v_row2.Gestionnaire                );
                                                                                              ecr( v_row2.DATE_DMS                    );
                                                                                              ecr(v_row2.amo_cache                    );
                                                                                              ecr(v_row2.vente_a_amortir              );
                                                                                              ecr(v_row2.nombre_mois                  );
                                                                                              ecr(v_row2.date_deb_amo_reel            );
                                                                                              ecr(v_row2.reste_a_amortir              );
                                                                                              ecr(v_row2.vente_amortie_apres_reneg    );
                                                                                              ecr(v_row2.REATRD_COMBLE                );
                                                                                              ecr(v_row2. SURPLUS_REPORT              );        
                                                                                              ecr(v_row2.reste_a_amortir_apres_reneg  );
                                                                                              ecr('CRLF'                              );                
                                                                                                                            
                                                                                              ecr ('##R'                              );
                                                                                              ecr(v_row3.bu                           );
                                                                                              ecr(v_row3.client                       );
                                                                                              ecr(v_row3.commercial                   );
                                                                                              ecr(v_row3.affaire                      );
                                                                                              ecr(v_row3.OTP                          );
                                                                                              ecr( v_row3.designation                 );
                                                                                              ecr( v_row3.TYPE_PRODUIT                );
                                                                                              ecr( v_row3.VEHICULE                    );
                                                                                              ecr( v_row3.Gestionnaire                );
                                                                                              ecr( v_row3.DATE_DMS                    );
                                                                                              ecr(v_row3.amo_cache                    );
                                                                                              ecr(v_row3.vente_a_amortir              );
                                                                                              ecr(v_row3.nombre_mois                  );
                                                                                              ecr(v_row3.date_deb_amo_reel            );
                                                                                              ecr(v_row3.reste_a_amortir              );
                                                                                              ecr(v_row3.vente_amortie_apres_reneg    );
                                                                                              ecr(v_row3.REATRD_COMBLE                );
                                                                                              ecr(v_row3. SURPLUS_REPORT              );        
                                                                                              ecr(v_row3.reste_a_amortir_apres_reneg  );
                                                                                              ecr('CRLF'                              );                                                   
                                                                                              ecr ('##TOTAL'                          );
                                                                                              ecr(v_row.bu                            );
                                                                                              ecr(v_row.client                        );
                                                                                              ecr(v_row.commercial                    );
                                                                                              ecr(v_row.affaire                       );
                                                                                              ecr(v_row.OTP                           );
                                                                                              ecr( v_row.designation                  );
                                                                                              ecr( v_row.TYPE_PRODUIT                 );
                                                                                              ecr( v_row.VEHICULE                     );
                                                                                              ecr( v_row.Gestionnaire                 );
                                                                                              ecr( v_row.DATE_DMS                     );
                                                                                              ecr(v_row.amo_cache                     );
                                                                                              ecr(v_row.vente_a_amortir               );
                                                                                              ecr(v_row.nombre_mois                   );
                                                                                              ecr(v_row.date_deb_amo_reel             );
                                                                                              ecr(v_row.reste_a_amortir               );
                                                                                              ecr(v_row.vente_amortie_apres_reneg     );
                                                                                              ecr(v_row.REATRD_COMBLE                 );
                                                                                              ecr(v_row. SURPLUS_REPORT               );        
                                                                                              ecr(v_row.reste_a_amortir_apres_reneg   );
                                                                                          ecr('CRLF');                                                                                                                   
                                                                                    ELSE
                                                                                            IF v_row3.TYPE IS NOT NULL THEN 
                                                                                                      ecr ('##R');
                                                                                                      ecr(v_row3.bu                           );
                                                                                                      ecr(v_row3.client                       );
                                                                                                      ecr(v_row3.commercial                   );
                                                                                                      ecr(v_row3.affaire                      );
                                                                                                      ecr(v_row3.OTP                          );
                                                                                                      ecr( v_row3.designation                 );
                                                                                                      ecr( v_row3.TYPE_PRODUIT                );
                                                                                                      ecr( v_row3.VEHICULE                    );
                                                                                                      ecr( v_row3.Gestionnaire                );
                                                                                                      ecr( v_row3.DATE_DMS                    );
                                                                                                      ecr(v_row3.amo_cache                    );
                                                                                                      ecr(v_row3.vente_a_amortir              );
                                                                                                      ecr(v_row3.nombre_mois                  );
                                                                                                      ecr(v_row3.date_deb_amo_reel            );
                                                                                                      ecr(v_row3.reste_a_amortir              );
                                                                                                      ecr(v_row3.vente_amortie_apres_reneg    );
                                                                                                      ecr(v_row3.REATRD_COMBLE                );
                                                                                                      ecr(v_row3. SURPLUS_REPORT              );        
                                                                                                      ecr(v_row3.reste_a_amortir_apres_reneg  );
                                                                                                      ecr('CRLF');  
                                                                                                END IF ;
                                                                                                                                   
                                                                                                IF (v_row2.TYPE IS NOT NULL )  THEN                                                  
                                                                                                          ecr ('##R');
                                                                                                          ecr(v_row2.bu                           );
                                                                                                          ecr(v_row2.client                       );
                                                                                                          ecr(v_row2.commercial                   );
                                                                                                          ecr(v_row2.affaire                      );
                                                                                                          ecr(v_row2.OTP                          );
                                                                                                          ecr( v_row2.designation                 );
                                                                                                          ecr( v_row2.TYPE_PRODUIT                );
                                                                                                          ecr( v_row2.VEHICULE                    );
                                                                                                          ecr( v_row2.Gestionnaire                );
                                                                                                          ecr( v_row2.DATE_DMS                    );
                                                                                                          ecr(v_row2.amo_cache                    );
                                                                                                          ecr(v_row2.vente_a_amortir              );
                                                                                                          ecr(v_row2.nombre_mois                  );
                                                                                                          ecr(v_row2.date_deb_amo_reel            );
                                                                                                          ecr(v_row2.reste_a_amortir              );
                                                                                                          ecr(v_row2.vente_amortie_apres_reneg    );
                                                                                                          ecr(v_row2.REATRD_COMBLE                );
                                                                                                          ecr(v_row2. SURPLUS_REPORT              );        
                                                                                                          ecr(v_row2.reste_a_amortir_apres_reneg  );
                                                                                                          ecr('CRLF');
                                                                                                END IF;
                                                                                    END IF;
                                                                          v_row2.TYPE := NULL;
                                                                         v_row3.TYPE := NULL;
                                                                      END IF;

                                                        END IF;
                                           v_dateHisto := v_row.date_histo ;
                                           v_n_ligne  :=   v_n_ligne + 1 ;
                                      END LOOP;
                                             
                                            IF PVL_STRCMP(  P_DETAIL    ,'O') = 1 THEN        
                                                    ecr ('##SUM'                          );       
                                                                     ecr( ' ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; '                             );
                                                                    ecr( v_SUM.Part_amo                                       );
                                                                    ecr(' ' );
                                                                    ecr(v_SUM.vente_a_amortir                         );
                                                                    ecr(' ;' );
                                                                    ecr(v_SUM.reste_a_amortir                             );
                                                                    ecr(v_SUM.vente_amortie_apres_reneg    );
                                                                    ecr(v_SUM.REATRD_COMBLE                          );
                                                                    ecr(v_SUM. SURPLUS_REPORT                         );        
                                                                    ecr(v_SUM.reste_a_amortir_apres_reneg  );                                                                                 
                                                                    ecr('CRLF');                           
                                           ELSIF PVL_STRCMP(  P_DETAIL    ,'N') = 1 THEN        
                                                    ecr ('##SUM'                          );       
                                                                     ecr( ' ; ; ; ; ; ; ; ; ; ; '                             );
                                                                    ecr(v_SUM.vente_a_amortir                         );
                                                                    ecr(' ; ' );
                                                                    ecr(v_SUM.reste_a_amortir                             );
                                                                    ecr(v_SUM.vente_amortie_apres_reneg    );
                                                                    ecr(v_SUM.REATRD_COMBLE                          );
                                                                    ecr(v_SUM. SURPLUS_REPORT                         );        
                                                                    ecr(v_SUM.reste_a_amortir_apres_reneg  );                                                                                 
                                                                    ecr('CRLF');                           
                                             END IF ;
                                           
                              close c1;   
                        exception When others Then                                        
                            ecr ('==========================================================================================================================');
                            BRB$FILE.ADD_LINE(Wfile2,'Message '  || substr(SQLERRM, 1, 200) );
                            BRB$FILE.ADD_LINE(Wfile2,'Requete ' || v_requete);
                    END; 
                    BRB$FILE.ADD_LINE(Wfile2,'NOMBRE LIGNES GENEREES:  ' || v_n_ligne );
                    ecr ('##T');                                   -- Les Titres fix  de l'excel
                    ecr ('SUIVI AMORTISSEMENT GROUPE PVL');         --PREMIER TITRE DE LA PAGE
                    ecr ('SITUATION AU : ' ||  v_dateHisto || CASE TRIM(P_DETAIL)
                                                                     WHEN 'O' THEN '   AVEC DETAIL'
                                                                     WHEN 'N' THEN '   SANS DETAIL'
                                                                     ELSE ''  END ) ;                                          
                                         
                      ecr ('AFFAIRE');   --NOM DE PREMIER PARAMETRE QUI VA ETRE DANS UN TABLEAU
                      ecr ('BU');        --NOM DU  DEUXIEME PARAMETRE QUI VA ETRE DANS UN TABLEAU
                      ecr ('CLIENT');    --NOM DU  TROISIEME PARAMETRE QUI VA ETRE DANS UN TABLEAU
                      ecr('CRLF');       -- FIN
                                         
                      ecr ('##P');
                      ecr (P_AFFAIRE );
                      ecr (  P_BU    );
                      ecr (P_CLIENT);
                      ecr('CRLF'); -- FIN

                     BRB$FILE.ADD_LINE(Wfile2,'Terminé  à : ' || to_char(sysdate,'DD/MM/YYYY HH24:MI'));
                     BRB$FILE.ADD_LINE(Wfile2,'***********************************************************');
                     BRB$FILE.ADD_LINE(Wfile2,'* Fin TPS.BRB_TPS0212P                  *');
                     BRB$FILE.ADD_LINE(Wfile2,'***********************************************************');
                     BRB$FILE.Close_File(Wfile1);
                     BRB$FILE.Close_File(Wfile2);                              
 Exception
            When  OTHERS  then
               BRB$FILE.ADD_LINE(Wfile2,'Terminé en ERREUR  à : ' || to_char(sysdate,'DD/MM/YYYY HH24:MI:SS'));
               BRB$FILE.ADD_LINE(Wfile2,'****************************************************************************************');
               BRB$FILE.ADD_LINE(Wfile2,'*  Fin transfert BRB_TPS0212P                                                               *');
               BRB$FILE.ADD_LINE(Wfile2,'****************************************************************************************');
               BRB$FILE.Close_File(Wfile2);    
                BRB$FILE.Close_File(Wfile1);                   
end;
/
