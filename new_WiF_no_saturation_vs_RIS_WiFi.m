%%%%%%%  made by Jungmin Yoon  %%%%%%%%%%%
%%%%%%%% WiFi_no_saturation_NOMA vs RIS_WiFi vs Conventional_WiFi(Final.ver)  %%%%%%%%%
clear;
clc;
close all;

W=[31,63]; %최소 Contention Window
m=[3,3];  %이진 진

Packet_Payload=8184;
MAC_hdr=272;
PHY_hdr=128;
Data=Packet_Payload+MAC_hdr+PHY_hdr; %Data bit size

ACK=112+PHY_hdr;
RTS=160+PHY_hdr;
CTS=112+PHY_hdr;
CTS_Timeout=300; 
Pkt_success_num=1000000;

RIS_Control=7000+MAC_hdr+PHY_hdr; %RIS 제어 message
RIS_RTS=RTS+200;  
RIS_CTS=CTS+200;
RIS_CTS_Timeout=CTS_Timeout+200;


Propagation_Delay=1;  %주어진 시간 변수
Slot_Time=50;
SIFS=28;
DIFS=128;

Total_Time_rc_n=zeros(1,length(W));    % WiFi_NOMA_no_saturation 전체 소요 시간
Total_Time_ris=zeros(1,length(W));  %RIS_WiFi  전체 소요 시간
Total_Time_rc=zeros(1,length(W)); %WiFi- conventional saturation

Station_Num=[20 30 40 50 70 100];

Throughput_rc_n=zeros(length(W),length(Station_Num)); %conventional+NOMA throughput
Throughput_rc=zeros(length(W),length(Station_Num)); %conventional throughput
Throughput_ris=zeros(length(W),length(Station_Num)); %ris_wifi throughput


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%    Wi-Fi_NOMA 의 RTS/CTS Access method      %%%%%%%%%%%%%%%%

for simul_rc_n=1:length(W)
    
    for station_rc_n=Station_Num
      
        Total_Time_rc_n=zeros(1,length(W));    %전체 소요 시간
        suc_pkt_rc_n=0;
        
        while suc_pkt_rc_n<Pkt_success_num %받으려는 전체 패킷 수  
            
            backoff_rc_n=randi([0,W(simul_rc_n)],[1,station_rc_n]);
            CWcase_rc_n=ones(1,station_rc_n);
            
            while sum(backoff_rc_n)~=0 %station 개수만큼 반복
                min_backoff_rc=min(backoff_rc_n);
                backoff_rc_n=backoff_rc_n-min_backoff_rc;
                Total_Time_rc_n(simul_rc_n)=Total_Time_rc_n(simul_rc_n)+DIFS+min_backoff_rc*Slot_Time;
                
                if  nnz(backoff_rc_n==0)>1 %충돌 나는 경우 backoff 0의 개수가 2 이상일때
                    col_case_rc=find(backoff_rc_n==0); %find: 조건에 맞는 숫자의 위치 정보 배열로 저장
                    
                    P_rc=zeros(1,length(backoff_rc_n));%NOMA를 위한 전체 high/low 확률
                    for i_p_rc=1:length(P_rc)
                        P_rc(i_p_rc)=rand;
                    end
                    P_col_rc=zeros(1,length(col_case_rc));% 충돌난 부분의 high/low
                    for i_pc=1:length(P_col_rc)
                        P_col_rc(i_pc)=P_rc(col_case_rc(i_pc));
                    end
                       
                    high_rc=0; %high low 개수 파악
                    low_rc=0;
                    for i_h_rc=1:length(P_col_rc)
                        if P_col_rc(i_h_rc)>0.5
                            high_rc=high_rc+1;
                        else
                            low_rc=low_rc+1;
                        end
                    end
                    
                    if high_rc==1
                        if low_rc==1 %Noma로 2개 전송 가능
                            suc_pkt_rc_n=suc_pkt_rc_n+2;
                            CWcase_rc_n(backoff_rc_n==0)=[];
                            backoff_rc_n(backoff_rc_n==0)=[];
                            Total_Time_rc_n(simul_rc_n)=Total_Time_rc_n(simul_rc_n)+(RTS+Propagation_Delay)+SIFS+(CTS+Propagation_Delay)+SIFS+(Data+Propagation_Delay)+SIFS+(ACK+Propagation_Delay);
                            
                        else %high 1개 성공 나머지 low 충돌
                            for i_cc_rc=1:length(col_case_rc)
                                if P_rc(col_case_rc(i_cc_rc))>0.5
                                    suc_pkt_rc_n=suc_pkt_rc_n+1;
                                    CWcase_rc_n(col_case_rc(i_cc_rc))=[];
                                    backoff_rc_n(col_case_rc(i_cc_rc))=[];
                                    Total_Time_rc_n(simul_rc_n)=Total_Time_rc_n(simul_rc_n)+(RTS+Propagation_Delay)+SIFS+(CTS+Propagation_Delay)+SIFS+(Data+Propagation_Delay)+SIFS+(ACK+Propagation_Delay);
                                    
                                    col_case_update=find(backoff_rc_n==0); 
                                    for i=1:length(col_case_update)
                                        if CWcase_rc_n(col_case_update(i))<m(simul_rc_n)
                                            backoff_rc_n(col_case_update(i))=randi([0, (W(simul_rc_n)+1)*2^(CWcase_rc_n(col_case_update(i)))-1]);
                                            CWcase_rc_n(col_case_update(i))=CWcase_rc_n(col_case_update(i))+1;
                                        else
                                            backoff_rc_n(col_case_update(i))=randi([0,(W(simul_rc_n)+1)*2^(CWcase_rc_n(col_case_update(i)))-1]);
                                        end
                                        
                                    end 
                                end
                            end 
                        end
                        
                    else % 충돌 high 2개 이상
                        for i=1:length(col_case_rc)
                            if CWcase_rc_n(col_case_rc(i))<m(simul_rc_n)
                                backoff_rc_n(col_case_rc(i))=randi([0, (W(simul_rc_n)+1)*2^(CWcase_rc_n(col_case_rc(i)))-1]);
                                CWcase_rc_n(col_case_rc(i))=CWcase_rc_n(col_case_rc(i))+1;
                            else
                                backoff_rc_n(col_case_rc(i))=randi([0,(W(simul_rc_n)+1)*2^(CWcase_rc_n(col_case_rc(i)))-1]);
                            end
                            Total_Time_rc_n(simul_rc_n)=Total_Time_rc_n(simul_rc_n)+RTS+Propagation_Delay+CTS_Timeout;
                        end 
                    end
  
                else %충돌 안난 경우
                    suc_pkt_rc_n=suc_pkt_rc_n+1;
                    CWcase_rc_n(backoff_rc_n==0)=[];
                    backoff_rc_n(backoff_rc_n==0)=[];
                    Total_Time_rc_n(simul_rc_n)=Total_Time_rc_n(simul_rc_n)+(RTS+Propagation_Delay)+SIFS+(CTS+Propagation_Delay)+SIFS+(Data+Propagation_Delay)+SIFS+(ACK+Propagation_Delay);
                end
            end
        end
        
        %RTS/CTS access throughput 계산
        if station_rc_n==Station_Num(1)
            Throughput_rc_n(simul_rc_n,1)=Throughput_rc_n(simul_rc_n,1)+suc_pkt_rc_n*(Packet_Payload)/Total_Time_rc_n(simul_rc_n);
        elseif station_rc_n==Station_Num(2)
            Throughput_rc_n(simul_rc_n,2)=Throughput_rc_n(simul_rc_n,2)+suc_pkt_rc_n*(Packet_Payload)/Total_Time_rc_n(simul_rc_n);
        elseif station_rc_n==Station_Num(3)
            Throughput_rc_n(simul_rc_n,3)=Throughput_rc_n(simul_rc_n,3)+suc_pkt_rc_n*(Packet_Payload)/Total_Time_rc_n(simul_rc_n);
        elseif station_rc_n==Station_Num(4)
            Throughput_rc_n(simul_rc_n,4)=Throughput_rc_n(simul_rc_n,4)+suc_pkt_rc_n*(Packet_Payload)/Total_Time_rc_n(simul_rc_n);
        elseif station_rc_n==Station_Num(5)
            Throughput_rc_n(simul_rc_n,5)=Throughput_rc_n(simul_rc_n,5)+suc_pkt_rc_n*(Packet_Payload)/Total_Time_rc_n(simul_rc_n);
        else
            Throughput_rc_n(simul_rc_n,6)=Throughput_rc_n(simul_rc_n,6)+suc_pkt_rc_n*(Packet_Payload)/Total_Time_rc_n(simul_rc_n);
        end
        
    end
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%%%%%%%%%%%%%%%%%%%%%%     RIS를 활용한 Wi-Fi_no_saturation simulation    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

for simul_ris=1:length(W) 
    
    for station_ris=Station_Num  
        
        Total_Time_ris=zeros(1,length(W));    %전체 소요 시간
        suc_pkt_ris=0;
        
        while suc_pkt_ris<Pkt_success_num %받으려는 전체 패킷 수 
            
            backoff_ris=randi([0,W(simul_ris)],[1,station_ris]);
            CWcase_ris=ones(1,station_ris);
            
            while sum(backoff_ris)~=0 %station 개수만큼 반복
                min_backoff_ris=min(backoff_ris);
                backoff_ris=backoff_ris-min_backoff_ris;
                Total_Time_ris(simul_ris)=Total_Time_ris(simul_ris)+DIFS+min_backoff_ris*Slot_Time;
                
                if  nnz(backoff_ris==0)>1 %충돌 나는 경우 backoff 0의 개수가 2 이상일때
                    col_case_ris=find(backoff_ris==0); %find: 조건에 맞는 숫자의 위치 정보 배열로 저장
                    
                    for i=1:length(col_case_ris)
                        if CWcase_ris(col_case_ris(i))<m(simul_ris)
                            backoff_ris(col_case_ris(i))=randi([0, (W(simul_ris)+1)*2^(CWcase_ris(col_case_ris(i)))-1]);
                            CWcase_ris(col_case_ris(i))=CWcase_ris(col_case_ris(i))+1;
                        else
                            backoff_ris(col_case_ris(i))=randi([0, (W(simul_ris)+1)*2^(CWcase_ris(col_case_ris(i)))-1]);
                        end
                        Total_Time_ris(simul_ris)=Total_Time_ris(simul_ris)+RIS_RTS+Propagation_Delay+RIS_CTS_Timeout;
                    end
                    
                else %충돌 안난 경우
                    suc_pkt_ris=suc_pkt_ris+1;
                    CWcase_ris(backoff_ris==0)=[];
                    backoff_ris(backoff_ris==0)=[];
                    Total_Time_ris(simul_ris)=Total_Time_ris(simul_ris)+(RIS_RTS+Propagation_Delay)+SIFS+(RIS_CTS+Propagation_Delay);
                end
            end
        end
        
        
        Total_Time_ris(simul_ris)=Total_Time_ris(simul_ris)+SIFS+(RIS_Control+Propagation_Delay)*ceil(Pkt_success_num/station_ris)+(Data+Propagation_Delay+SIFS+ACK+Propagation_Delay)*ceil(Pkt_success_num/2);
        
        % RIS_WiFi throughput 계산
        if station_ris==Station_Num(1)
            Throughput_ris(simul_ris,1)=Throughput_ris(simul_ris,1)+Pkt_success_num*(Packet_Payload)/Total_Time_ris(simul_ris);
        elseif station_ris==Station_Num(2)
            Throughput_ris(simul_ris,2)=Throughput_ris(simul_ris,2)+Pkt_success_num*(Packet_Payload)/Total_Time_ris(simul_ris);
        elseif station_ris==Station_Num(3)
            Throughput_ris(simul_ris,3)=Throughput_ris(simul_ris,3)+Pkt_success_num*(Packet_Payload)/Total_Time_ris(simul_ris);
        elseif station_ris==Station_Num(4)
            Throughput_ris(simul_ris,4)=Throughput_ris(simul_ris,4)+Pkt_success_num*(Packet_Payload)/Total_Time_ris(simul_ris);
        elseif station_ris==Station_Num(5)
            Throughput_ris(simul_ris,5)=Throughput_ris(simul_ris,5)+Pkt_success_num*(Packet_Payload)/Total_Time_ris(simul_ris);
        else
            Throughput_ris(simul_ris,6)=Throughput_ris(simul_ris,6)+Pkt_success_num*(Packet_Payload)/Total_Time_ris(simul_ris);
        end
  
    end
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%  Conventional Wi-Fi %%%%%%%%%%%%%%%%%%%%%%%%%

for simul_rc=1:length(W)
    
    for station_rc=Station_Num
      
        %Total_Time_rc(simul_rc)=0; %전체 시간
        Total_Time_rc=zeros(1,length(W));    %전체 소요 시간
        suc_pkt_rc=0;
        backoff_rc=randi([0,W(simul_rc)-1],[1,station_rc]);
        CWcase_rc=ones(1,station_rc);
        
        while suc_pkt_rc<1000000 %받으려는 전체 패킷 수  
            
            min_backoff=min(backoff_rc);
            backoff_rc=backoff_rc-min_backoff;
            Total_Time_rc(simul_rc)=Total_Time_rc(simul_rc)+DIFS+min_backoff*Slot_Time;

            if  nnz(backoff_rc==0)>1 %충돌 나는 경우 backoff 0의 개수가 2 이상일때
                col_case=find(backoff_rc==0); %find: 조건에 맞는 숫자의 위치 정보 배열로 저장

                for i=1:length(col_case)
                    if CWcase_rc(col_case(i))<m(simul_rc)
                        backoff_rc(col_case(i))=randi([0, W(simul_rc)*2^(CWcase_rc(col_case(i)))-1]);
                        CWcase_rc(col_case(i))=CWcase_rc(col_case(i))+1;
                    else
                        backoff_rc(col_case(i))=randi([0,W(simul_rc)*2^(CWcase_rc(col_case(i)))-1]);
                    end
                    Total_Time_rc(simul_rc)=Total_Time_rc(simul_rc)+RTS+Propagation_Delay;
                end

            else %충돌 안난 경우
                suc_pkt_rc=suc_pkt_rc+1;
                for i_b=1:length(backoff_rc)
                    if backoff_rc(i_b)==0
                        backoff_rc(i_b)=backoff_rc(i_b)+randi([0,W(simul_rc)-1]);
                    end
                end

                Total_Time_rc(simul_rc)=Total_Time_rc(simul_rc)+(RTS+Propagation_Delay)+SIFS+(CTS+Propagation_Delay)+SIFS+(Data+Propagation_Delay)+SIFS+(ACK+Propagation_Delay);
            end
        
        end
        
         %RTS/CTS access throughput 계산
        if station_rc==Station_Num(1)
            Throughput_rc(simul_rc,1)=Throughput_rc(simul_rc,1)+suc_pkt_rc*(Packet_Payload)/Total_Time_rc(simul_rc);
        elseif station_rc==Station_Num(2)
            Throughput_rc(simul_rc,2)=Throughput_rc(simul_rc,2)+suc_pkt_rc*(Packet_Payload)/Total_Time_rc(simul_rc);
        elseif station_rc==Station_Num(3)
            Throughput_rc(simul_rc,3)=Throughput_rc(simul_rc,3)+suc_pkt_rc*(Packet_Payload)/Total_Time_rc(simul_rc);
        elseif station_rc==Station_Num(4)
            Throughput_rc(simul_rc,4)=Throughput_rc(simul_rc,4)+suc_pkt_rc*(Packet_Payload)/Total_Time_rc(simul_rc);
        elseif station_rc==Station_Num(5)
            Throughput_rc(simul_rc,5)=Throughput_rc(simul_rc,5)+suc_pkt_rc*(Packet_Payload)/Total_Time_rc(simul_rc);
        else
            Throughput_rc(simul_rc,6)=Throughput_rc(simul_rc,6)+suc_pkt_rc*(Packet_Payload)/Total_Time_rc(simul_rc);
        end
        
        
    end
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


figure
hold on; grid on;

plot(Station_Num,Throughput_ris(1,:),'-xr','MarkerSize',8);
plot(Station_Num,Throughput_ris(2,:),'-or','MarkerSize',8);

plot(Station_Num,Throughput_rc_n(1,:),'-xb','MarkerSize',8);
plot(Station_Num,Throughput_rc_n(2,:),'-ob','MarkerSize',8);

plot(Station_Num,Throughput_rc(1,:),'-xg','MarkerSize',8);
plot(Station_Num,Throughput_rc(2,:),'-og','MarkerSize',8);

xlabel('Number of Stations');
ylabel('System Throughput');
ylim([0.5, 1.3]);

legend('Proposed, W=31, m=3', 'Proposed, W=63, m=3', 'Conventional+NOMA, W=31, m=3', 'Conventional+NOMA, W=63, m=3', 'Conventional, W=31, m=3', 'Conventional, W=63, m=3')















