
DECLARE



TYPE t_HIST IS  RECORD (

 REF_PIECE varchar2(500) ,
 
  code_client varchar2(500) := NULL , 
  
  LANCEMENT varchar2(500) := NULL , 
  
  DATE_DEBUT DATE :=  to_date('01/01/1901','MM/DD/YYYY'),
  
  DATE_FIN  DATE:=  to_date('01/10/2050','dd/mm/yyyy')
  
  );

v_line t_HIST ;

v_nblignes_i number := 0 ;

v_queryAsString varchar2(1000);


 CURSOR C0( C_ref_piece varchar2 ) IS 
                                                                                                select distinct 
                                                                                                            R.LANCEMENT ,
                                                                                                            R.DATE_DEBUT ,
                                                                                                            nvl( R.DATE_FIN , to_date('01/10/2050','dd/mm/yyyy')) AS  DATE_FIN 
                                                                                                  from LANCEMENT_detail D , LANCEMENT L , ref_piece_amortie  R
                                                                                                   where  D.LANCEMENT = L.ID AND R.LANCEMENT = L.ID AND  D.DATE_DEBUT = 
                                                                                                                (select max(d1.date_debut) from LANCEMENT_DETAIL d1 where d1. lancement =  D.LANCEMENT) AND 
                                                                                                           R.REF_PIECE =   C_ref_piece    ;
                                                                                                           
CURSOR C1    ( C_ref_piece varchar2 , C_LANCEMENT varchar2  ) IS                                                                  
                                                                                                 select distinct   
                                                                                                                D.DATE_DEBUT ,
                                                                                                                nvl( D.DATE_FIN , to_date('01/10/2050','dd/mm/yyyy'))AS  DATE_FIN       
                                                                                                  from  LANCEMENT_detail D
                                                                                                   where D.DATE_DEBUT = 
                                                                                                                (select max(d1.date_debut) from LANCEMENT_DETAIL d1 where d1. lancement =  D.LANCEMENT) 
                                                                                                                AND D.LANCEMENT =  C_LANCEMENT ;

CURSOR C2 (  C_LANCEMENT varchar2  ) IS
                                                                                                select distinct CODE_CLIENT , DATE_DEBUT ,nvl( DATE_FIN , to_date('01/10/2050','dd/mm/yyyy'))AS  DATE_FIN   
                                                                                                from client_code_amo
                                                                                                where LANCEMENT = C_LANCEMENT AND CODE_CLIENT LIKE '%' || '' || '%' ;
                                                                                                
CURSOR C3(C_REF_PIECE  varchar2 , C_CODE_CLIENT varchar2 , C_DATE_DEBUT DATE , C_DATE_FIN DATE )
  IS
             SELECT  ref_client , ltrim(client_do,'0') as client_do  , CODESOCPPA , sum(quantite) AS SOMME
             FROM  amort_hist_sap  
             where  ref_client  =  '98029780WP'  AND ltrim(client_do , '0')  =  C_CODE_CLIENT
             and date_facture >= C_DATE_DEBUT  and date_facture  <=  C_DATE_FIN
            group by ref_client, CLIENT_DO , CODESOCPPA
            order by ref_client, CLIENT_DO  , CODESOCPPA ;
 /*          
CURSOR C_InsertResult( C_LANCEMENT varchar2 , C_REF_PIECE  varchar2 , C_CODE_CLIENT varchar2 , C_CODE_SOC varchar2 , C_QUANTITE varchar2  DATE_DEBUT DATE , DATE_FIN DATE ) IS
INSERT INTO AMORTISSEMENT_PIECE (LANCEMENT,REF_PIECE,CODE_CLIENT,CODE_SOC,QUANTITE,AN_MOIS,REGUL,CREATED_BY,CREATION_DATE,LAST_UPDATED_BY,LAST_UPDATE_DATE)
VALUES( C_LANCEMENT , C_REF_PIECE  ,   C_CODE_CLIENT  ,   C_CODE_SOC    ,   C_QUANTITE   , SYSDATE ,'O' , USER, SYSDATE , USER ,  SYSDATE) ;
*/
BEGIN
        v_line.REF_PIECE        :=  '98029780WP'   ;
        v_line.code_client        :=  NULL ;
        
        FOR ele IN C0( v_line.REF_PIECE ) LOOP
                     v_line.LANCEMENT :=  ele.LANCEMENT ;
                      v_line.DATE_DEBUT :=  ele.DATE_DEBUT ;                                                     
                     v_line.DATE_FIN := ele.DATE_FIN  ;        
                     
                                   for data1 IN C1(v_line.REF_PIECE , ele.LANCEMENT )  LOOP

                                                            IF data1.DATE_DEBUT > v_line.DATE_DEBUT  THEN
                                                                    v_line.DATE_DEBUT := data1.DATE_DEBUT  ;
                                                            END IF;
                                                            
                                                            IF data1.DATE_FIN  <  v_line.DATE_FIN THEN
                                                                    v_line.DATE_FIN := data1.DATE_FIN  ;
                                                            END IF;
                                                                                          
                                    END LOOP;    
                                    
                                    
                                    for data2 IN C2(ele.LANCEMENT )  LOOP

                                                            IF data2.DATE_DEBUT > v_line.DATE_DEBUT  THEN
                                                                    v_line.DATE_DEBUT := data2.DATE_DEBUT  ;
                                                            END IF;
                                                            
                                                            IF data2.DATE_FIN  <  v_line.DATE_FIN THEN
                                                                    v_line.DATE_FIN := data2.DATE_FIN  ;
                                                            END IF;
                                                            
                                                  v_line.code_client  := data2.code_client  ;
                                                  
                                                                         FOR result IN C3( v_line.REF_PIECE ,     v_line.code_client ,  v_line.DATE_DEBUT  , v_line.DATE_FIN   ) LOOP
                                                                         v_queryAsString :=   
                                                                         'INSERT INTO AMORTISSEMENT_PIECE (LANCEMENT,REF_PIECE,CODE_CLIENT,CODE_SOC,QUANTITE,AN_MOIS,REGUL,CREATED_BY,CREATION_DATE,LAST_UPDATED_BY,LAST_UPDATE_DATE)' ||
                                                                         'VALUES('''|| v_line.LANCEMENT || ''',''' || result.ref_client || ''',''' ||result.client_do  || ''',''' || result.CODESOCPPA    || ''',' || result.SOMME   || ', SYSDATE ,''O'' , USER , SYSDATE , USER  ,  SYSDATE)' ;
                                                                              
                                                                                BEGIN
                                                                                
                                                                                -- INSERT INTO AMORTISSEMENT_PIECE (LANCEMENT,REF_PIECE,CODE_CLIENT,CODE_SOC,QUANTITE,AN_MOIS,REGUL,CREATED_BY,CREATION_DATE,LAST_UPDATED_BY,LAST_UPDATE_DATE)
                                                                                -- VALUES( v_line.LANCEMENT,  result.ref_client ,  result.client_do   ,  result.CODESOCPPA     ,   result.SOMME    , SYSDATE ,'O' , USER, SYSDATE , USER ,  SYSDATE) ;
                                                                                 ROLLBACK;
                                                                                 
                                                                                EXCEPTION 
                                                                                    WHEN OTHERS THEN
                                                                                                null;
                                                                                END;
                                                                         
                                                                                 --DBMS_OUTPUT.PUT_LINE( v_queryAsString);
                                                                               DBMS_OUTPUT.PUT_LINE(result.ref_client||  '    |     '  ||    result.client_do || '    |     ' ||  v_line.LANCEMENT  || '  |   ' ||  result.SOMME  || '  |   ' ||  v_line.DATE_DEBUT  || '    |   ' || v_line.DATE_FIN);
                                                                                
                                                                            END LOOP;      
                                                                                          
                                    END LOOP;    
                      
               v_line.code_client        :=  NULL ;
               v_line.LANCEMENT     := NULL ;
        
        END LOOP;
        
 
END;
