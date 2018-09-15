clc; close all; clear;
%% 输入参数
fs=1190; % 采样频率
% 读取路径
date='.\0913';
set='\lmy_fallA';
peakLen=35; % 10 35
isGCC=0; cacheSize=20;
Debug=0; % 设为1时注意不要一次性处理太多数据
limit=-1; 
L=1220; 
%% 设置切断函数参数
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
% 噪声
load('noise');
% 创建文件夹
if ~exist(outpath,'dir') %判断是否存在这个文件夹，若不存在则创建该文件夹
    mkdir(outpath); %创建文件夹
end
delete ([outpath '*']);

dirs=dir(basepath);
saveIndex=0;
for i=1:size(dirs,1)
    disp([basepath,dirs(i).name]);
    if(dirs(i).name(1) == '.')
        continue
    end
    
    %% 读取文件
    load([basepath,dirs(i).name]);

    %% 降采样,滤波
    data1=segmentSample(1,:);
    data2=segmentSample(2,:);
    data3=segmentSample(3,:);
    data1=highpass(data1,fs,10);
    data2=highpass(data2,fs,10);
    data3=highpass(data3,fs,10); 
    
    %% 切断
    data1(1:edge)=[]; data2(1:edge)=[]; data3(1:edge)=[];
    data=sum([data1;data2;data3],1);
    
    [result,beg_,end_]=seg_var(data,fs,thresIn,Debug,peakLen);
%         [beg_,end_,peakSize]=my_sig_seg_old(data,fs,Lm,Rm,ethresh(i-2),minlen,maxInter,minInter,segLen,Debug);

    if(result==1) % 成功切段
        % 清除非法端点
        while (beg_(1)<=0)
            beg_(1)=[];
            end_(1)=[];
            if(length(beg_)<=0)
                fprintf([dirs(i).name,':error\n']);
                break;
            end
        end
        
        %% 限定切段个数
        if limit~=-1
            if length(beg_)>limit
                beg_=beg_(1:limit);
                end_=end_(1:limit);       
            end
        end
        
        %% 分装存储
        for k=1:length(beg_)
            seg_data=[data1(beg_(k):end_(k));data2(beg_(k):end_(k));data3(beg_(k):end_(k))];
            %% GCC
            if isGCC==1
                load('baseSignal2');
                data = batchGCC( baseSignal2, seg_data, cacheSize );
            else
                data=seg_data;
            end
            
            %% 拼接噪声
            if isConcatNoise==1
                data = [data noise(:,1:L-length(data))];
            end
            
            % Save
            saveIndex=saveIndex+1;
            save([outpath,num2str(saveIndex)],'data');
        end
        %% 画图
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

% Lm=7; %帧长
% Rm=3.2; %帧移
% ethresh = [15,15,18,15,18,18,18]; %能量最小阈值
% minlen  = 3; %最短的脚步声的长度（用于去除长度太小的峰）
% maxInter=40; %同一个脚步声的相邻峰的最大间隔(用于合并同一个脚步声的相邻峰)
% minInter=100; %不同脚步声的相邻峰的最小间隔(用于去除大于最小长度，但相邻间隔太小的峰)
% segLen=40; %切割每一个信号的长度（帧数）