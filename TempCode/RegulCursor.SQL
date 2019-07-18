
DECLARE 


 CURSOR C1( C_REF_PIECE varchar2) IS 
 
 select distinct CODE_CLIENT 
 FROM CLIENT_CODE_AMO 
 where  LANCEMENT IN 
            (
                                                select ID
                                                 from lancement
                                                where id in (
                                                                                select R.LANCEMENT
                                                                                from ref_piece_amortie  R , LANCEMENT L , LANCEMENT_DETAIL D
                                                                                where    
                                                                                              R.DATE_DEBUT = (select max(P1.date_debut) from REF_PIECE_AMORTIE P1  where P1.REF_PIECE = R.REF_PIECE)
                                                                                        AND D.DATE_DEBUT = (select max(d1.date_debut) from LANCEMENT_DETAIL d1 where d1. lancement = L.ID)
                                                                                       AND L.ID = R.LANCEMENT AND  L.ID = D.LANCEMENT 
                                                                                      AND REF_PIECE =  '98029780WP' 
                                                                                )
            ) AND CODE_CLIENT  LIKE '%' ;
            
            
            
            
 CURSOR C2(C_REF_PIECE  varchar2 , C_CODE_CLIENT varchar2 )
  IS
 SELECT distinct ref_client ,to_char( to_number(client_do)) as client_do  , sum(quantite) AS SOMME
 FROM  amort_hist_sap  
 where  ref_client  =  '98029780WP'  AND to_char( to_number(TRIM(client_do)))  LIKE C_CODE_CLIENT 
group by ref_client, CLIENT_DO ;


BEGIN

        FOR ele in C1( '98029780WP' ) LOOP
        
            FOR sth IN c2('98029780WP',ele.CODE_CLIENT ) LOOP
            
                dbms_output.PUT_LINE(' ref_client       |       client_do       |       sum(quantite) ');
                 dbms_output.PUT_LINE( '98029780WP'||'          |           '|| sth.CLIENT_DO  ||'          |           '|| sth.SOMME );
            
            END LOOP;
             
        END LOOP;


END;



