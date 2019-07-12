CREATE OR REPLACE PROCEDURE TPS.BRB_TPS0212P

 (P_JOB          IN Number
 ,P_AFFAIRE IN Varchar2 
 ,P_BU            IN Varchar2
 ,P_CLIENT    IN Varchar2 
 ,P_DETAIL    IN Varchar2
 ,P_TYPE_G  IN Varchar2
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
Wfile1           UTL_FILE.FILE_TYPE;
Wfile2           UTL_FILE.FILE_TYPE;
Wnbenr          Number := 0;
Winstance      Varchar2(30);
v_requete VARCHAR2(10000) ;

TYPE t_sample IS RECORD
      (

        date_histo                  varchar2(100),
        affaire                     varchar2(100),
        client                      varchar2(100),
        bu                          varchar2(100),
        commercial                  varchar2(100),
        num_chrono                  varchar2(100),
        designation                 varchar2(100),
        type_g                      varchar2(100),
        vente_a_amortir             varchar2(100),
        quantite_prev               varchar2(100),
        qte_tot_amo                 varchar2(100),
        amorti_du_mois              varchar2(100),
        nombre_mois                 varchar2(100),
        date_deb_amo_reel           varchar2(100),
        reste_a_amortir             varchar2(100),
        vente_amortie_apres_reneg   varchar2(100),
        reste_a_amortir_apres_reneg varchar2(100),
        observation                 varchar2(800)
      );

v_row t_sample ;

Function GenerateQuery( F_DETAIL IN VARCHAR2 , F_AFFAIRE IN VARCHAR2 , F_BU IN VARCHAR2 , F_client   IN VARCHAR2 , F_type_g IN VARCHAR2 ) RETURN VARCHAR2 IS
-- (P_DETAIL ,P_AFFAIRE ,P_BU,P_CLIENT , P_TYPE_G );

    v_amo_cache_gby varchar2(10) := '';

BEGIN

    if TRIM(F_DETAIL) = 'O' OR TRIM(F_DETAIL) = 'o' then
           --v_amo_cache      := 'amo_cache,';
           v_amo_cache_gby  := ',amo_cache';
    end if ;
 return 'select to_char(date_histo,''DD/MM/YYYY'') date_histo,
    affaire,
    client,
    bu,
    commercial,
    num_chrono,
    designation,
    type_g,
    sum(vente_a_amortir) vente_a_amortir,
    sum(quantite_prev) quantite_prev,
    sum(qt_tot_amo) qte_tot_amo,
    sum(amorti_du_mois) amorti_du_mois,
    max(nombre_mois) nombre_mois,
    min(to_char(date_deb_amo_reel,''DD/MM/YYYY'')) date_deb_amo_reel ,
    sum(reste_a_amortir) reste_a_amortir,
    sum(vente_amortie_apres_reneg) vente_amortie_apres_reneg,
    sum(reste_a_amortir_apres_reneg) reste_a_amortir_apres_reneg,
    observation
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
                    replace(a.observation,chr(10),'' '')                                                                                                                  observation,
                    a.vehicule                                                                                                                                          vehicule,
                    l.amo_cache                                                                                                                                         amo_cache,
                    l.type_g                                                                                                                                            type_g,
                    l.retard_dms                                                                                                                                        retard_dms,
                    a.date_dms                                                                                                                                          date_dms,
                    d.date_deb_amorti                                                                                                                                   debut_amort_theo,
                    l.id                                                                                                                                                id_lanc,
                    l.type_budget                                                                                                                                       type_budget,
                    L.EOTP                                                                                                                                              eotp,
                    decode(l.type_g, ''FIN'', ''PPA'', l.type_g)                                                                                                             type_gestionnaire,
                    l.gestionnaire                                                                                                                                      gestionnaire,
                    L.CALCUL_PS                                                                                                                                         calcul_ps,
                    L.PFAE_COMPTA                                                                                                                                       fae_compta,
                    L.SOP_DMS                                                                                                                                           sop,
                    l.num_chrono                                                                                                                                        num_chrono,
                    decode(l.type_budget, ''RETROCESSION AMORTISSEMENT'', -1 * d.bdg_vente_amortie_out,d.bdg_vente_amortie_out)                                           vente_a_amortir,
                    decode(l.type_budget, ''RETROCESSION AMORTISSEMENT'', -1 * d.bdg_vente_amort_sfi,d.bdg_vente_amort_sfi)                                               vente_amort_ssfi,
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
                    bai.baisse                                                                                                                                          baisse
            from affaire a,
                lancement l,
                lancement_detail d,
                type_budget t,
                V_AFFAIRE_GRP_SOC_VALIDE g,
                (select lancement, vente_amo_rea, vente_amo_nego from amort_vente_rea v
                where v.date_histo = (select max(v1.date_histo) from amort_vente_rea v1 where v1.lancement = v.lancement)) vt,
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
            and l.type_budget <> ''REVISION AMORTISSEMENT''
            and L.CLOS_FIN = ''N'')
            where affaire LIKE ''%' || F_AFFAIRE || '%'' AND client LIKE ''%' || F_client || '%'' AND bu LIKE ''%' || F_BU ||  '%''
            group by client, bu,commercial,num_chrono,designation,observation, affaire,date_histo,type_g ' || v_amo_cache_gby ||
            '   having       type_g      LIKE ''%'|| F_type_g || '%''';

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


     ecr ('##P');
     ecr (P_AFFAIRE);
     ecr (P_CLIENT);
     ecr (P_BU);
     ecr('CRLF');
     ecr ('##H;client;bu;commercial;affaire;designation;vente_a_amortir;nombre_mois;date_deb_amo_reel ;reste_a_amortir ;vente_amortie_apres_reneg ;reste_a_amortir_apres_reneg;observation');
     ecr('CRLF');

     --v_requete := GenerateQuery(TRIM( P_DETAIL),TRIM( P_AFFAIRE) , TRIM( P_CLIENT) , TRIM( P_BU  )  , TRIM(P_type_g)  );  -- DETAIL , AFFAIRE , CLIENT , BU , type_g
     
       v_requete := GenerateQuery(P_DETAIL ,P_AFFAIRE ,P_BU,P_CLIENT , P_TYPE_G );  -- (P_DETAIL ,P_AFFAIRE ,P_BU,P_CLIENT , P_TYPE_G );

                        BEGIN
                              open c1 for  v_requete ;
                                      loop
                                          fetch c1 into v_row ;
                                            EXIT WHEN c1%NOTFOUND ;
                                              ecr('##R'                              );
                                              ecr(v_row.client                       );
                                              ecr(v_row.bu                           );
                                              ecr(v_row.commercial                   );
                                              ecr(v_row.affaire                      );
                                              ecr(v_row.designation                  );
                                              ecr(v_row.vente_a_amortir              );
                                              ecr(v_row.nombre_mois                  );
                                              ecr(v_row.date_deb_amo_reel            );
                                              ecr(v_row.reste_a_amortir              );
                                              ecr(v_row.vente_amortie_apres_reneg    );
                                              ecr(v_row.reste_a_amortir_apres_reneg  );
                                              ecr(v_row.observation                  );
                                              ecr('CRLF');
                                      end loop;
                              close c1;
                              
                              
                        exception
                                  When others Then
                                    BRB$FILE.ADD_LINE(Wfile2,'Message '  || substr(SQLERRM, 1, 200) );
                                    BRB$FILE.ADD_LINE(Wfile2,'Requete ' || v_requete);
                         END;


     BRB$FILE.ADD_LINE(Wfile2,'Terminé  à : ' || to_char(sysdate,'DD/MM/YYYY HH24:MI'));

     BRB$FILE.ADD_LINE(Wfile2,'***********************************************************');
     BRB$FILE.ADD_LINE(Wfile2,'* Fin TPS.BRB_TPS0212P                  *');
     BRB$FILE.ADD_LINE(Wfile2,'***********************************************************');


     BRB$FILE.Close_File(Wfile1);
     BRB$FILE.Close_File(Wfile2);



end;
/
