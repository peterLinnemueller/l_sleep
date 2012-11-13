% get meg spindle peak distribution:
D = spm_eeg_load


% fid = fopen('figure_case.tex', 'w');
% fprintf(fid, '\\subsection{Analysis Items}\n');
% fprintf(fid, '\\frame\n{\n\\frametitle{Analysis Parameters}\n\\begin{tiny}\\begin{table}\n\\caption{Analysis Parameter Table}\n\\rowcolors[]{2}{blue!10}{blue!20}\n\\begin{tabular}{l l l l}\n\\toprule\n\\textbf{Analysis Name} & Threshold 1 & Threshold 2 & Comments \\\\\n\\midrule');
% for i=AnaSel
%   fprintf(fid, '\n\\textbf{%s} & %.2f & %.2f & %s\\\\', Analysis{i}.Name, Analysis{i}.Thr, Analysis{i}.Thr2, Analysis{i}.Comment);
% end
% 
% fprintf(fid, '\n\\bottomrule\n\\end{tabular}\n\\end{table}\\end{tiny}\n}\n');
% 
% 
% % Generating Structual Checking Images
% fprintf(fid, '\\section{Patients Case Study}\n\n');
% 
% fprintf(fid, '\\subsection{Preprocessing Check}\n');
% 
% fprintf(fid, '\\subsubsection{T1 Structual Image Check}\n');
% print('-depsc2', figname);

%%
THRESH = 1.5%1.5 % exclude trials with std > THRESH, Amr paper: 1.5

for condNr=1:size(D.condlist,2)
  
  indChanMEGGRAD = find(strcmp('MEGGRAD',D.chantype));
  indTrialCond = find(strcmp(D.condlist{condNr},D.conditions));
  
  data = D(indChanMEGGRAD,:,indTrialCond);
  
  data_std = squeeze(std(data,0,2)); % std  per trial per channel
  data_mean = squeeze(mean(data,2)); % mean per trial per channel
  data_std_mean = mean(data_std,2);  % mean std trials per channel
  
  figure(110+condNr); plot(data_std_mean,'*')
  hold on;
  plot(mean(data_std_mean)*ones(length(data_std_mean),1))
  plot(1.5*mean(data_std_mean)*ones(length(data_std_mean),1),'r')
  hold off;
  
  M = ones(size(data_std));
  for i=1:size(data_std,1)
    colIndExclTrl = find(data_std_mean(i)*THRESH < data_std(i,:));
    M(i,colIndExclTrl) = 0;
  end
  
  figure(110+condNr); clf;
    subplot(4,2,[1:6])
      imagesc(M);
      colormap('Gray'); %axis image
      set(gca,'YTick',1:length(indChanMEGGRAD))
      tmp = indChanMEGGRAD;
      tmp(1:2:end) = []; 
      set(gca,'YTickLabel', D.chanlabels(tmp))
      s = sprintf('white: [std(trial_chanX) > %f*mean(allTrials_chanX)]\n%s\n%s',THRESH, fullfile(D.path,D.fname),D.condlist{condNr})
      title(s,'Interpreter','none')
      xlabel('trials')
      ylabel('MEG sensors')

    subplot(4,2,[7 8])
      %   plot(log10(sum(M,1)),'k*');
      semilogy(sum((M-1)*(-1),1),'k*');
      xlim([1,size(data,3)])
      xlabel('trials')
      ylabel('#affected sensors')
  
  figname = ['l_trialsMegStdThreshold_',D.fname,'_cond',num2str(condNr),'_',date,'.eps'];
  print('-depsc2', figname);
end

%%
D = spm_eeg_load
  indChanMEGGRAD = find(strcmp('MEGGRAD',D.chantype)); %MEGGRAD
%   indChanMEGGRAD = [306:311] % EEG only
  indTrialCond = find(strcmp(D.condlist{1},D.conditions));
  
  data = D(indChanMEGGRAD,:,indTrialCond);
  figure(201); clf;
  [p_chan, p_tp] = meshgrid(1:size(data,2), 1:size(data,1));
  p_data =  squeeze(data(:,:,1));
%   mesh(p_tp, p_chan, p_data)
% ribbon(p_data(1:10:end,round(end/2)-100:round(end/2)+100)')
% ribbon(mean(p_data,1))
m1 = mean(data,3);
m2 = mean(m1,1);
ribbon(m1)
  

 %% embedding
 E=spm_eeg_load('fmfdedfspm8_subj2_sleep_20090312_01.mat')
 
 x = squeeze(E([306:308],:,1))'; % filtered averaged EEG spindle Cz 
 
 N = length(x);
for i = 1 : 30
    r = corrcoef(x(1 : N - i), x(1 + i : end));
    C(i) = r(1,2);
end

figure(401); clf; 
plot(C)
xlabel('Delay'), ylabel('Autocorrelation')
grid on

%% embedding dim is first x with f(x)=y=0, here: tau=4
% NB: better with mutual information!
figure(402); clf;
tau = 4;
subplot(2,2,1)
h=plot3(x(1:end-2*tau,1),x(1+tau:end-tau,1),x(1+2*tau:end,1))
% h=plot3(x(1:end-2*tau),x(1+tau:end-tau),x(1+2*tau:end))
set(h,'LineWidth',3)
view(-105,32)
xlabel('x_1'), ylabel('x_2'), zlabel('x_3')
grid on
subplot(2,2,2)
h=plot3(x(1:end-2*tau,2),x(1+tau:end-tau,2),x(1+2*tau:end,2))
% h=plot3(x(1:end-2*tau),x(1+tau:end-tau),x(1+2*tau:end))
set(h,'LineWidth',3)
view(-105,32)
xlabel('x_1'), ylabel('x_2'), zlabel('x_3')
grid on
subplot(2,2,3)
h=plot3(x(1:end-2*tau,3),x(1+tau:end-tau,3),x(1+2*tau:end,3))
% h=plot3(x(1:end-2*tau),x(1+tau:end-tau),x(1+2*tau:end))
set(h,'LineWidth',3)
view(-105,32)
xlabel('x_1'), ylabel('x_2'), zlabel('x_3')
grid on
subplot(2,2,4)
h=plot3(x(:,1),x(:,2),x(:,3))
% h=plot3(x(1:end-2*tau),x(1+tau:end-tau),x(1+2*tau:end))
set(h,'LineWidth',3)
view(-105,32)
xlabel('x_1'), ylabel('x_2'), zlabel('x_3')
grid on

%% tisean

tiseanPath = '/home/leonhard/programs/TISEAN/Tisean_3.0.1/bin/'

a = 1.4;
system([tiseanPath,'henon -B0.3 -A',num2str(a),' -l1000 -o']);
x = load('henon.dat');

plot(x(:,1),x(:,2),'.')

figure(gcf + 1)
x = [];
for a = 0:.02:2
    system([tiseanPath,'henon -B0 -A',num2str(a),' -l200 -o -V0']);
    henonData = load('henon.dat');
    x = [x, henonData(:,1)];
end
plot(0:.02:2, x', 'k.')


