clc; close all; clear;
%% �������
fs=1190; % ����Ƶ��
% ��ȡ·��
date='.\0913';
set='\lmy_fallA';
peakLen=35; % 10 35
isGCC=0; cacheSize=20;
Debug=0; % ��Ϊ1ʱע�ⲻҪһ���Դ���̫������
limit=-1; 
L=1220; 
%% �����жϺ�������
thresIn=1.0;
edge=100;
%% BatchCut

if peakLen==35
    isConcatNoise=0;
else 
    isConcatNoise=1;
end

basepath=[date,set,'\'];
if isConcatNoise==1
    outpath=[date,'_processed_',num2str(fs),'hz\',set,'_Noise\'];
else
    outpath=[date,'_processed_',num2str(fs),'hz\',set,'\'];
end
% ����
load('noise');
% �����ļ���
if ~exist(outpath,'dir') %�ж��Ƿ��������ļ��У����������򴴽����ļ���
    mkdir(outpath); %�����ļ���
end
delete ([outpath '*']);

dirs=dir(basepath);
saveIndex=0;
for i=1:size(dirs,1)
    disp([basepath,dirs(i).name]);
    if(dirs(i).name(1) == '.')
        continue
    end
    
    %% ��ȡ�ļ�
    load([basepath,dirs(i).name]);

    %% ������,�˲�
    data1=segmentSample(1,:);
    data2=segmentSample(2,:);
    data3=segmentSample(3,:);
    data1=highpass(data1,fs,10);
    data2=highpass(data2,fs,10);
    data3=highpass(data3,fs,10); 
    
    %% �ж�
    data1(1:edge)=[]; data2(1:edge)=[]; data3(1:edge)=[];
    data=sum([data1;data2;data3],1);
    
    [result,beg_,end_]=seg_var(data,fs,thresIn,Debug,peakLen);
%         [beg_,end_,peakSize]=my_sig_seg_old(data,fs,Lm,Rm,ethresh(i-2),minlen,maxInter,minInter,segLen,Debug);

    if(result==1) % �ɹ��ж�
        % ����Ƿ��˵�
        while (beg_(1)<=0)
            beg_(1)=[];
            end_(1)=[];
            if(length(beg_)<=0)
                fprintf([dirs(i).name,':error\n']);
                break;
            end
        end
        
        %% �޶��жθ���
        if limit~=-1
            if length(beg_)>limit
                beg_=beg_(1:limit);
                end_=end_(1:limit);       
            end
        end
        
        %% ��װ�洢
        for k=1:length(beg_)
            seg_data=[data1(beg_(k):end_(k));data2(beg_(k):end_(k));data3(beg_(k):end_(k))];
            %% GCC
            if isGCC==1
                load('baseSignal2');
                data = batchGCC( baseSignal2, seg_data, cacheSize );
            else
                data=seg_data;
            end
            
            %% ƴ������
            if isConcatNoise==1
                data = [data noise(:,1:L-length(data))];
            end
            
            % Save
            saveIndex=saveIndex+1;
            save([outpath,num2str(saveIndex)],'data');
        end
        %% ��ͼ
        figure;
        subplot(3,1,1); plot(data1);
        subplot(3,1,2); plot(data2);
        subplot(3,1,3); plot(data3);
        hold on;
        for loop=1:length(beg_)
            plot([beg_(loop),beg_(loop)],[min(data3),max(data3)],'r');
            plot([end_(loop),end_(loop)],[min(data3),max(data3)],'r');
            text(beg_(loop),max(data1),num2str(loop));
            title(['The LAST CUT FROM ' dirs(i).name ' TO ' num2str(saveIndex)]);
        end
        
        fprintf(['peakNum:-----------------',num2str(length(beg_)),'\n']);
    else
        fprintf([dirs(i).name,':error\n']);
    end
    
end

% Lm=7; %֡��
% Rm=3.2; %֡��
% ethresh = [15,15,18,15,18,18,18]; %������С��ֵ
% minlen  = 3; %��̵ĽŲ����ĳ��ȣ�����ȥ������̫С�ķ壩
% maxInter=40; %ͬһ���Ų��������ڷ�������(���ںϲ�ͬһ���Ų��������ڷ�)
% minInter=100; %��ͬ�Ų��������ڷ����С���(����ȥ��������С���ȣ������ڼ��̫С�ķ�)
% segLen=40; %�и�ÿһ���źŵĳ��ȣ�֡����