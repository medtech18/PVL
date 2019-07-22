DECLARE 


 CURSOR C1( C_REF_PIECE varchar2) IS 
                        select distinct  CODE_CLIENT,
                                                                                                     MIN(GREATEST(T1.DATE_DEBUT , C.DATE_DEBUT ))
                                                                                                AS DATE_DEBUT ,
                                                                                                    MIN(LEAST(T1.DATE_FIN ,nvl(C.DATE_FIN , to_date('01/10/2050','dd/mm/yyyy') )) )
                                                                                                  AS DATE_FIN
                         FROM CLIENT_CODE_AMO  C  ,  (     

                                                                                                select distinct  R.REF_PIECE ,  L.ID  , GREATEST( R.DATE_DEBUT ,  D.DATE_DEBUT ) AS DATE_DEBUT ,
                                                                                                                                LEAST(
                                                                                                                                                       nvl(R.DATE_FIN , to_date('01/10/2050','dd/mm/yyyy')) ,
                                                                                                                                                       nvl(D.DATE_FIN , to_date('01/10/2050','dd/mm/yyyy'))  
                                                                                                                                            ) AS DATE_FIN
                                                                                                  from ref_piece_amortie  R , LANCEMENT L , LANCEMENT_DETAIL D
                                                                                                   where    
                                                                                                                 D.DATE_DEBUT = (select max(d1.date_debut) from LANCEMENT_DETAIL d1 where d1. lancement = L.ID)
                                                                                                               AND L.ID = R.LANCEMENT AND  L.ID = D.LANCEMENT 
                                                                                                              AND REF_PIECE =  '98029780WP' )  T1
                    where C.LANCEMENT = T1.ID AND CODE_CLIENT LIKE '%100180%'
                    group by  CODE_CLIENT ;                   
            
 CURSOR C2(C_REF_PIECE  varchar2 , C_CODE_CLIENT varchar2 , C_DATE_DEBUT DATE , C_DATE_FIN DATE )
  IS
     SELECT distinct ref_client , ltrim(client_do,'0') as client_do  , sum(quantite) AS SOMME
     FROM  amort_hist_sap  
     where  ref_client  =  '98029780WP'  AND ltrim(client_do , '0')  LIKE '%' || C_CODE_CLIENT || '%' 
      and date_facture >= C_DATE_DEBUT  and date_facture  <=  C_DATE_FIN  
    group by ref_client, CLIENT_DO ;
    
    
    
v_tempo C1%ROWTYPE ;


BEGIN

        FOR ele in C1('98029780WP') LOOP
                            for result in C2('98029780WP',ele.CODE_CLIENT ,ele.DATE_DEBUT , ele.DATE_FIN  ) LOOP
                              DBMS_OUTPUT.PUT_LINE(result.ref_client||  '    |     '  ||    result.client_do || '    |     ' ||  result.SOMME  || '  |   ' ||  ele.DATE_DEBUT  || '    |   ' || ele.DATE_FIN);
                            END LOOP; 
        END LOOP;

END;
