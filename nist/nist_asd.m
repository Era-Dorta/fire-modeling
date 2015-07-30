% nist_lines.m - Retrieves data from the online NIST Atomic Spectra Database
% eg: nistln=nist_asd('He',150,1500), figure,plot_asd_lines
%
% history: 
% 20111209 written by A. N. James for Lawrence Livermore National Laboratory at Princeton Plasma Physics Laboratory
% 20120830 updated to latest version of NIST ASD 

%{
This URL found by downloading http://physics.nist.gov/PhysRefData/ASD/lines_form.html and changing the form method to 'get', then submitting the form and copying out the address

http://physics.nist.gov/cgi-bin/ASD/lines1.pl?encodedlist=XXT1XXR0q0qVqVIII&spectra=He&low_wl=150&upp_wn=&upp_wl=1500&low_wn=&unit=0&submit=Retrieve+Data&temp=&doppler=&eden=&iontemp=&java_window=3&java_mult=&format=1&line_out=0&remove_js=on&en_unit=0&output=0&page_size=15&show_obs_wl=1&show_calc_wl=1&order_out=0&max_low_enrg=&show_av=2&max_upp_enrg=&tsb_value=0&min_str=&A_out=0&intens_out=on&max_str=&allowed_out=1&forbid_out=1&min_accur=&min_intens=&conf_out=on&term_out=on&enrg_out=on&J_out=on&g_out=on

file:///cgi-bin/ASD/lines1.pl?encodedlist=XXT1XXR0q0qVqVIII&spectra=He&low_wl=150&upp_wn=&upp_wl=1500&low_wn=&unit=0&submit=Retrieve+Data&temp=&doppler=&eden=&iontemp=&java_window=3&java_mult=&format=1&line_out=0&en_unit=0&output=0&page_size=15&show_obs_wl=1&show_calc_wl=1&order_out=0&max_low_enrg=&show_av=2&max_upp_enrg=&tsb_value=0&min_str=&A_out=0&intens_out=on&max_str=&allowed_out=1&forbid_out=1&min_accur=&min_intens=&conf_out=on&term_out=on&enrg_out=on&J_out=on&g_out=on
%}

function [nistln varargout]=nist_asd(spec,lowwl,uppwl,varargin);
if ~isempty(varargin), order=varargin{1}; else, order=1; end

%      spec='Ar I',lowwl=10,uppwl=10000,order=1,nist_asd

lowwl=lowwl/order; 
uppwl=uppwl/order;

spec(find(spec'+0==32))='+';

%spec='He+I';lowwl=150; uppwl=1500;

nisturl='http://physics.nist.gov/cgi-bin/ASD/lines1.pl';

postdata=[ ...
 'encodedlist=XXT1XXR0q0qVqVIII' '&' ... % some key to make it work?
 'spectra=' spec '&' ... % eg 'He' or 'He+I' or 'He+II', no spaces
 'low_wl=' num2str(lowwl) '&' ...
 'upp_wl=' num2str(uppwl) '&' ...
 'unit=1' '&' ... % wl unit 0=Angstroms, 1=nm, 2=um
 'en_unit=0' '&' ... % energy unit 0 cm^-1, 1 eV, 2 Rydberg
 'low_wn=' '&' ...
 'upp_wn=' '&' ...
 'submit=Retrieve+Data' '&' ...
 'temp=' '&' ...
 'doppler=' '&' ...
 'eden=' '&' ...
 'iontemp=' '&' ...
 'java_window=3' '&' ...
 'java_mult=' '&' ...
 'tsb_value=0' '&' ...
 'format=1' '&' ... % 0 HTML output, 1 ascii output
 'remove_js=on' '&' ... % cleans up output for easier parsing
 'output=0' '&' ... % 0 return all output, 1 return output in pages
 'page_size=15' '&' ...
 'line_out=0' '&' ... % 0 return all lines, 1 only w/trans probs, 2 only w/egy levl, 3 only w/obs wls
 'order_out=0' '&' ... % output ordering: 0 wavelength, 1 multiplet
 'show_av=2' '&' ... % show wl in Vacuum (<2000A) Air (2000-20000A) Vacuum (>20,000A)
 'max_low_enrg=' '&' ... % maximum lower level energy
 'max_upp_enrg=' '&' ... % maximum upper level energy
 'min_str=' '&' ... % minimum transition strength
 'max_str=' '&' ... % maximum transition strength
 'min_accur=' '&' ... % minimum line accuracy, eg AAA AA A B C
 'min_intens=' '&' ... % minimum relative intensity to return
 'show_obs_wl=1' '&' ... % show observed wavelength
 'show_calc_wl=1' '&' ... % show calculated wavelength
 'A_out=0' '&' ... % show ...
 'intens_out=on' '&' ... % show relative intensity
 'allowed_out=1' '&' ... % show allowed transitions
 'forbid_out=1' '&' ... % show forbidden transitions
 'conf_out=on' '&' ... % show electron configuration
 'term_out=on' '&' ... % show terms
 'enrg_out=on' '&' ... % show transition energies
 'J_out=on' '&' ... % show J
 'g_out=on' ... % show g
 ];

%{
wget -q -O - 'http://physics.nist.gov/cgi-bin/ASD/lines1.pl?encodedlist=XXT1XXR0q0qVqVIII&spectra=He&low_wl=150&upp_wn=&upp_wl=1500&low_wn=&unit=0&submit=Retrieve+Data&temp=&doppler=&eden=&iontemp=&java_window=3&java_mult=&format=1&line_out=0&remove_js=on&en_unit=0&output=0&page_size=15&show_obs_wl=1&show_calc_wl=1&order_out=0&max_low_enrg=&show_av=2&max_upp_enrg=&tsb_value=0&min_str=&A_out=0&intens_out=on&max_str=&allowed_out=1&forbid_out=1&min_accur=&min_intens=&conf_out=on&term_out=on&enrg_out=on&J_out=on&g_out=on' | sed -n '/\<pre\>/,/pre\>/p' | sed '/pre>/d' | less
%}

% This issues as a GET instead of POST, but it works ok anyway...
[err result]=system(['wget -q -O - "' nisturl '?' postdata '" ' ...
                        '| sed -n "/<pre*/,/<\/pre>/p"' ... % select lines between <pre> tags
                        '| sed "/<*pre>/d"' ... % remove <pre> lines
                        ... %'| sed "/----*/d"' ... % remove ---- lines
                        ]);

spec(find(spec'+0==43))=' ';


nln=0;
clear nistln;

if err, disp('Error retrieving NIST data.')
else
 res=result;

 % Extract header info
 [tok res]=strtok(res,char(10)); % char(10) is some sort of line break
 [hd1 res]=strtok(res,char(10));
 [hd2 res]=strtok(res,char(10));
 [hd3 res]=strtok(res,char(10));
 hd{1}=strtrim(regexp(hd1,'\|','split'));
 hd{2}=strtrim(regexp(hd2,'\|','split'));
 hd{3}=strtrim(regexp(hd3,'\|','split'));
 for ii=1:length(hd{1}), hdr{ii}=strtrim([hd{1}{ii} ' ' hd{2}{ii} ' ' hd{3}{ii}]); end
 hdr={hdr{1:end-1}};

 while ~isempty(res) & ~isempty(hdr)
  %[tok res]=strtok(res,'\n'); % \n doesn't work for some reason?
  [tok res]=strtok(res,char(10)); % char(10) is a line break
  tok=strtrim(tok);

  if strncmp(tok,'----',4), for dum=1:4, [tok res]=strtok(res,char(10)); end, continue, end
  if isempty(tok) | strncmp(tok,'|',1), continue, end % skip divider lines


  if strcmp(hdr{1},'Spectrum')
   [spec obs ritz rint Aki Acc EiEk lconf lterm lJ uconf uterm uJ gigk Type dum] = strread(tok,'%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s','delimiter','|');
  else
   [     obs ritz rint Aki Acc EiEk lconf lterm lJ uconf uterm uJ gigk Type dum] = strread(tok,'%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s','delimiter','|');
  end
  Ei=str2num(EiEk{1}(1:strfind(EiEk{:},'-')-1));
  Ek=str2num(EiEk{1}(strfind(EiEk{:},'-')+1:end));

  nln=nln+1;
  nistln(nln)=struct('spec',strtrim(spec), ...
                     'obs',str2num(cell2mat(obs))*order, ...
                     'ritz',str2num(cell2mat(ritz))*order, ...
                     'meanor',mean([str2num(cell2mat(obs)) str2num(cell2mat(ritz))])*order, ...
                     'rint',str2num(cell2mat(rint)), ...
                     'Aki',str2num(cell2mat(Aki)), ...
                     'Acc',strtrim(cell2mat(Acc)), ...
                     'Ei',Ei,'Ek',Ek, ...
                     'lconf',strtrim(cell2mat(lconf)), ...
                     'lterm',strtrim(cell2mat(lterm)), ...
                     'lJ',strtrim(cell2mat(lJ)), ...
                     'uconf',strtrim(cell2mat(uconf)), ...
                     'uterm',strtrim(cell2mat(uterm)), ...
                     'uJ',strtrim(cell2mat(uJ)), ...
                     'gigk',strtrim(cell2mat(Type)), ...
                     'Type',strtrim(cell2mat(Type)), ...
                     'order',order ...
                     );
  if order>1, nistln(nln).spec=[nistln(nln).spec ' (2nd order)']; end
 end %~isempty(res)
end % if err

if nln==0, disp('No lines found in the range.'), nistln=[]; end

if nargout>1, varargout{1}=result; end

%{
wlmin=15; wlmax=1500;
elements={'H' 'He' 'Li' 'Be' 'B' 'C' 'N' 'O' 'F' 'Ne' 'Na' 'Mg' 'Al' 'Si' ...
'Ar' 'Kr' 'Xe' 'Cr' 'Fe' 'Co' 'Ni' 'Cu' 'Zn' 'Mo' 'Ta' 'W' }
for ii=1:length(elements),spec=elements{ii};
 nistln=nist_asd(spec,wlmin,wlmax)
 figure('name',['NIST ASD - ' spec])
 plot_asd_lines
 set(gcf,'pos',[5 1099 1120 420])
 set(gca,'xlim',[wlmin wlmax])
 print('-depsc',[spec ' VUV.eps'])
end
%}
