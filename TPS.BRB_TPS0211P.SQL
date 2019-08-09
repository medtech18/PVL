CREATE OR REPLACE PROCEDURE TPS.BRB_TPS0211P

 (P_JOB IN Number
 ,P_REF_PIECE varchar2
 ,P_CODE_CLIENT varchar2
 ,P_DATE_REGUL varchar2
 ,P_SIMULATION varchar2
 )
 IS






/**************************************************************************************************
Auteur   : mElasri
Date     : 19/07/2019
Fonction : Régularisation des quantitées
***************************************************************************************************/

Cursor C_instance is
   SELECT name
   FROM      sys.v_$database;

Cursor C_Param is
   SELECT repertoire,separateur,suffixe_dat,suffixe_log,base_script
   FROM      ADM_INT_PARAM;


CURSOR C0(C_REF_PIECE varchar2 ) IS
    select distinct r.lancement ,
           greatest (r.date_debut ,d.date_debut) as date_debut ,
           least(nvl( r.date_fin , to_date('01/10/2050','dd/mm/yyyy')),nvl( d.date_fin , to_date('01/10/2050','dd/mm/yyyy'))) as  date_fin
     from lancement_detail d ,
          lancement l ,
          ref_piece_amortie  r
     where  d.lancement = l.id
     and r.lancement = l.id
     and  d.date_debut = (select max(d1.date_debut) from lancement_detail d1 where d1. lancement =  d.lancement)
     and  r.ref_piece =   C_REF_PIECE;

CURSOR C2 (C_LANCEMENT varchar2,C_CODE_CLIENT varchar2) IS
    select distinct code_client ,
           date_debut ,
    nvl( date_fin , to_date('01/10/2050','dd/mm/yyyy'))as  date_fin
    from client_code_amo
    where lancement = C_LANCEMENT
    and code_client like '%' ||C_CODE_CLIENT|| '%';

CURSOR C3(C_REF_PIECE  varchar2 , C_CODE_CLIENT varchar2 , C_DATE_DEBUT DATE , C_DATE_FIN DATE ) IS
    select ref_client ,
           ltrim(client_do,'0') as client_do,
           codesocppa,
           sum(quantite) as somme
    from  amort_hist_sap
    where ref_client  =  C_REF_PIECE
    and ltrim(client_do , '0')  =  C_CODE_CLIENT
    and date_facture >= C_DATE_DEBUT
    and date_facture  <=  C_DATE_FIN
    group by ref_client, client_do , codesocppa;

WParam          C_Param%Rowtype;
Wfile2          UTL_FILE.FILE_TYPE;
Wfile1          UTL_FILE.FILE_TYPE;
Winstance            Varchar2(30);


TYPE t_HIST IS  RECORD
(
ref_piece   varchar2(500) ,
code_client varchar2(500) := null ,
lancement   varchar2(500) := null ,
date_debut  date          :=  to_date('01/01/1901','MM/DD/YYYY'),
date_fin    date          :=  to_date('01/10/2050','dd/mm/yyyy')
);

v_line t_HIST ;
v_nblignes_i number := 0 ;
v_queryAsString varchar2(1000);


TYPE counter_type IS RECORD
(
value  number := 0 );
TYPE t_counterTab IS TABLE OF counter_type INDEX BY BINARY_INTEGER;
v_resume_tab  t_counterTab ;
i number:=0;
BEGIN
                 Open  C_instance;
                 Fetch C_instance into Winstance;
                 Close C_Instance;

                 Open  C_Param;
                 Fetch C_Param into WParam;
                 Close C_Param;

                 Wfile2 := BRB$FILE.Open_File(WParam.repertoire,'tps0211_' || P_Job || '.' || WParam.suffixe_log);
                 Wfile1 := BRB$FILE.Open_File(WParam.repertoire,'tps0211_' || P_Job || '.' || WParam.suffixe_dat);

                 BRB$FILE.ADD_LINE(Wfile2,'*********************************************************************************************');
                 BRB$FILE.ADD_LINE(Wfile2,'*Régularisation des quantitées                                                              *');
                 BRB$FILE.ADD_LINE(Wfile2,'*********************************************************************************************');
                 BRB$FILE.ADD_LINE(Wfile2,'Instance   : ' || Winstance);
                 BRB$FILE.ADD_LINE(Wfile2,'Commencé à : ' || to_char(sysdate,'DD/MM/YYYY HH24:MI:SS'));

                BEGIN
                        v_line.REF_PIECE        := TRIM(P_REF_PIECE)   ;
                         IF TRIM(P_SIMULATION) = 'O' OR  TRIM(P_SIMULATION) = 'o'  THEN
                                 BRB$FILE.ADD_LINE(Wfile1,'REF_PIECE;CODE_CLIENT;CODE_SOC;QUANTITE; AN_MOIS;REGUL; LANCEMENT; DATE_DEBUT_L; DATE_FIN_L;');
                         END IF;

                         FOR ele IN C0( v_line.REF_PIECE ) LOOP
                                v_line.LANCEMENT    :=  ele.LANCEMENT ;
                                v_line.DATE_DEBUT   :=  ele.DATE_DEBUT ;
                                v_line.DATE_FIN     := ele.DATE_FIN  ;
                                for data2 IN C2( ele.LANCEMENT,TRIM(P_CODE_CLIENT)) LOOP
                                    IF data2.DATE_DEBUT > v_line.DATE_DEBUT  THEN
                                          v_line.DATE_DEBUT := data2.DATE_DEBUT  ;
                                    END IF;
                                    IF data2.DATE_FIN  <  v_line.DATE_FIN THEN
                                            v_line.DATE_FIN := data2.DATE_FIN  ;
                                    END IF;
                                    v_line.code_client  := data2.code_client  ;
                                    FOR result IN C3( v_line.REF_PIECE,v_line.code_client ,v_line.DATE_DEBUT  , v_line.DATE_FIN   ) LOOP
                                            v_queryAsString :=
                                            'INSERT INTO AMORTISSEMENT_PIECE (LANCEMENT,REF_PIECE,CODE_CLIENT,CODE_SOC,QUANTITE,AN_MOIS,REGUL,CREATED_BY,CREATION_DATE,LAST_UPDATED_BY,LAST_UPDATE_DATE)' ||
                                            'VALUES('''|| v_line.LANCEMENT || ''',''' || result.ref_client || ''',''' ||result.client_do  || ''',''' || result.CODESOCPPA    || ''',' || result.SOMME   || ', to_date('''||P_DATE_REGUL || ''',''dd/mm/yyyy'' ,''O'' , USER , SYSDATE , USER  ,  SYSDATE)' ;
                                            IF P_SIMULATION = 'O' THEN
                                                   BRB$FILE.ADD_LINE(Wfile1, result.ref_client||';'||   result.client_do  || ';'  ||     result.CODESOCPPA   || ';'|| result.SOMME ||';'||P_DATE_REGUL ||';'|| 'O' || ';'||v_line.LANCEMENT||';'||to_char( v_line.DATE_DEBUT,'dd/mm/yyyy') ||';'||to_char( v_line.DATE_FIN,'dd/mm/yyyy')||';');
                                            ELSE
                                                BEGIN

                                                    INSERT INTO AMORTISSEMENT_PIECE
                                                        (LANCEMENT,
                                                        REF_PIECE,
                                                        CODE_CLIENT,
                                                        CODE_SOC,
                                                        QUANTITE,
                                                        AN_MOIS,
                                                        REGUL,
                                                        CREATED_BY,
                                                        CREATION_DATE,
                                                        LAST_UPDATED_BY,
                                                        LAST_UPDATE_DATE)
                                                    VALUES( v_line.LANCEMENT,
                                                        result.ref_client,
                                                        result.client_do,
                                                        result.CODESOCPPA,
                                                        result.SOMME,
                                                        to_date(P_DATE_REGUL,'dd/mm/yyyy') ,
                                                        'O',
                                                        USER,
                                                        SYSDATE,
                                                        USER,
                                                        SYSDATE) ;
                                                   -- ROLLBACK;
                                                      COMMIT;
                                                EXCEPTION
                                                    WHEN OTHERS THEN
                                                         BRB$FILE.ADD_LINE(Wfile2,'Impossible de Régulariser la Quantité pour la Piece : ' || result.ref_client  || 'du Client' ||   result.client_do || 'de la période :' ||  v_line.DATE_DEBUT || 'à' || v_line.DATE_FIN );
                                                         BRB$FILE.ADD_LINE(Wfile2,'Message '  || substr(SQLERRM, 1, 200) );
                                                         BRB$FILE.ADD_LINE(Wfile2,'Requete ' ||  v_queryAsString );
                                                END;
                                            END IF;
                                               if v_resume_tab.exists(v_line.code_client) then
                                                v_resume_tab(v_line.code_client).value := v_resume_tab(v_line.code_client).value + 1 ;
                                            else
                                                v_resume_tab(v_line.code_client).value := 1 ;
                                            end if ;
                                            v_nblignes_i  :=  v_nblignes_i  +1 ;
                                    END LOOP;
                            END LOOP;
                               v_line.code_client        :=  NULL ;
                               v_line.LANCEMENT     := NULL ;
                         END LOOP;
                         
                        EXCEPTION
                                    WHEN OTHERS THEN
                                         BRB$FILE.ADD_LINE(Wfile2,'Message '  || substr(SQLERRM, 1, 200) );
                END;
                BRB$FILE.ADD_LINE(Wfile2,'');
                i := nvl(  v_resume_tab.FIRST,0);
                WHILE i <> 0 LOOP
                     BRB$FILE.ADD_LINE(Wfile2,'Nombre de lignes integrées pour la piece :'||   P_REF_PIECE || ' et  le client N° : ' || i || ' :  ' ||  v_resume_tab(i).value);
                     i := nvl(v_resume_tab.NEXT(i),0);  -- Get next element of array
                     EXIT WHEN i = 0 ;
                END LOOP;
                

                BRB$FILE.ADD_LINE(Wfile2,'nombre de lignes integrées TOTAL : '|| v_nblignes_i );
                BRB$FILE.ADD_LINE(Wfile2,'');
                BRB$FILE.ADD_LINE(Wfile2,'Terminé  à : ' || to_char(sysdate,'DD/MM/YYYY HH24:MI:SS'));
                BRB$FILE.ADD_LINE(Wfile2,'****************************************************************************************');
                BRB$FILE.ADD_LINE(Wfile2,'*  Fin transfert BRB_TPS0211P                                                              *');
                BRB$FILE.ADD_LINE(Wfile2,'****************************************************************************************');
                BRB$FILE.Close_File(Wfile2);
                 BRB$FILE.Close_File(Wfile1);
                 
        EXCEPTION                
                When OTHERS then
                BRB$FILE.ADD_LINE(Wfile2,'SQL CODE '  || SQLCODE );
                BRB$FILE.ADD_LINE(Wfile2,'Message '  || substr(SQLERRM, 1, 200) );
               BRB$FILE.ADD_LINE(Wfile2,'Terminé en ERREUR  à : ' || to_char(sysdate,'DD/MM/YYYY HH24:MI:SS'));
               BRB$FILE.ADD_LINE(Wfile2,'****************************************************************************************');
               BRB$FILE.ADD_LINE(Wfile2,'*  Fin transfert BRB_TPS0206P                                                               *');
               BRB$FILE.ADD_LINE(Wfile2,'****************************************************************************************');
               BRB$FILE.Close_File(Wfile2);
               BRB$FILE.Close_File(Wfile1);
 
         END;
/
