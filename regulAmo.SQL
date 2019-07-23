
DECLARE



TYPE t_HIST IS  RECORD ( REF_PIECE varchar2(500) , code_client varchar2(500) := NULL , DATE_DEBUT DATE , DATE_FIN DATE ) ;

v_line t_HIST ;



CURSOR c0 IS 
           select distinct CODE_CLIENT  from client_code_amo
        where lancement in  (
            select distinct lancement from ref_piece_amortie
            where ref_piece = '98029780WP'
            ) ;
            

CURSOR C1(C_CODE_CLIENT varchar2 )  IS
      select distinct lancement , DATE_DEBUT ,nvl( DATE_FIN , to_date('01/10/2050','dd/mm/yyyy'))AS  DATE_FIN 
      from client_code_amo
      where  CODE_CLIENT = C_CODE_CLIENT ;


 CURSOR C2(C_LANCEMENT varchar2 ,  C_DATE_DEBUT DATE , C_DATE_FIN DATE  ) IS 
                                                                                                select distinct 
                                                                                                   CASE
                                                                                                                      WHEN (DATE_DEBUT > C_DATE_DEBUT )
                                                                                                                        THEN DATE_DEBUT 
                                                                                                                        ELSE  C_DATE_DEBUT
                                                                                                   END   AS  DATE_DEBUT  ,
                                                                                                  CASE
                                                                                                                      WHEN (nvl( R.DATE_FIN , to_date('01/10/2050','dd/mm/yyyy')) > C_DATE_FIN )
                                                                                                                        THEN C_DATE_FIN 
                                                                                                                        ELSE  nvl( R.DATE_FIN , to_date('01/10/2050','dd/mm/yyyy'))
                                                                                                    END  AS  DATE_FIN        
 
                                                                                                  from ref_piece_amortie  R
                                                                                                   where  R.LANCEMENT  = C_LANCEMENT AND REF_PIECE =  '98029780WP'     ;

  CURSOR C3( C_LANCEMENT varchar2, C_DATE_DEBUT DATE , C_DATE_FIN DATE) IS  
                                                                                                  select distinct   
                                                                                                   CASE
                                                                                                                      WHEN (DATE_DEBUT > C_DATE_DEBUT )
                                                                                                                        THEN DATE_DEBUT 
                                                                                                                        ELSE  C_DATE_DEBUT
                                                                                                   END   AS  DATE_DEBUT  ,
                                                                                                  CASE
                                                                                                                      WHEN (nvl( D.DATE_FIN , to_date('01/10/2050','dd/mm/yyyy')) > C_DATE_FIN )
                                                                                                                        THEN C_DATE_FIN 
                                                                                                                        ELSE  nvl( D.DATE_FIN , to_date('01/10/2050','dd/mm/yyyy'))
                                                                                                    END  AS  DATE_FIN                     
                                                                                                  from  LANCEMENT_detail D
                                                                                                   where    
                                                                                                                D.DATE_DEBUT = 
                                                                                                                (select max(d1.date_debut) from LANCEMENT_DETAIL d1 where d1. lancement =  D.LANCEMENT)
                                                                                                               AND D.LANCEMENT = C_LANCEMENT ;
                                

 CURSOR C4(C_REF_PIECE  varchar2 , C_CODE_CLIENT varchar2 , C_DATE_DEBUT DATE , C_DATE_FIN DATE )
  IS
     SELECT distinct ref_client , ltrim(client_do,'0') as client_do  , sum(quantite) AS SOMME
     FROM  amort_hist_sap  
     where  ref_client  =  '98029780WP'  AND ltrim(client_do , '0')  =  C_CODE_CLIENT
     and date_facture >= C_DATE_DEBUT  and date_facture  <=  C_DATE_FIN
    group by ref_client, CLIENT_DO ;
    
        
v_tempo C1%ROWTYPE ;

BEGIN
        v_line.REF_PIECE        :=  '98029780WP';
        
        FOR ele in C0 LOOP  
                 v_line.code_client :=  ele.code_CLIENT ;

                   FOR data1 IN C1(ele.code_CLIENT) LOOP
                         v_line.DATE_DEBUT  :=  data1.DATE_DEBUT  ;
                          v_line.DATE_FIN         :=  data1.DATE_FIN  ;
                            
                        open C2(data1.LANCEMENT , data1.DATE_DEBUT , data1.DATE_FIN ) ;
                        fetch C2  INTO  v_line.DATE_DEBUT, v_line.DATE_FIN ;
                        
                        if C2%FOUND THEN 
                        
                                               open C3(data1.LANCEMENT , data1.DATE_DEBUT , data1.DATE_FIN ) ;
                                                 fetch C3  INTO  v_line.DATE_DEBUT, v_line.DATE_FIN ;
                                                 
                                                 CLOSE C3 ;

                        END IF;
                        
                        CLOSE C2 ;
                          
                   
                   END LOOP;
        
       
                            FOR result IN C4( v_line.REF_PIECE ,     v_line.code_client ,  v_line.DATE_DEBUT  , v_line.DATE_FIN   ) LOOP 
              
                                DBMS_OUTPUT.PUT_LINE(result.ref_client||  '    |     '  ||    result.client_do || '    |     ' ||  result.SOMME  || '  |   ' ||  v_line.DATE_DEBUT  || '    |   ' || v_line.DATE_FIN);
                                
                             END LOOP;      
                          
                           v_line.DATE_DEBUT  :=  NULL  ;
                          v_line.DATE_FIN         :=  NULL  ;
                           v_line.code_client   :=   NULL  ;
        
        END LOOP;

END;
