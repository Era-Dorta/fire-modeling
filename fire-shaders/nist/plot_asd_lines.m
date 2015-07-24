% eg: spec='He',nistln=nist_asd(spec,150,1500),figure('name',['NIST ASD - ' spec]),plot_asd_lines
% eg: spec='Xe',nistln=nist_asd(spec,150,1500),figure('name',['NIST ASD - ' spec]),plot_asd_lines

specs=unique({nistln.spec});
if length(specs)>1, colors=jet(length(specs)); end

if ~exist('normasd','var'), normasd=1, end
if ~exist('minint','var'), minint=1e-1, end % a bit above zero so that lines show on log plots

mxrint=1;
for ii=1:length(nistln)
 if ~isempty(nistln(ii).rint) & nistln(ii).rint>mxrint
  mxrint=nistln(ii).rint;
 end
end

hnist=[]; hlgnd=[];
%figure
hold on, box on
for ii=1:length(nistln)
 if length(specs)>1, colr=colors(find(strcmp(nistln(ii).spec,specs)),:);
 else colr='k';
 end

 if isempty(nistln(ii).rint)
  hnist(ii)=plot(nistln(ii).meanor,minint,'.-','color',colr);
 else
  hnist(ii)=plot(repmat(nistln(ii).meanor,1,2),[minint nistln(ii).rint*normasd/mxrint],'-','color',colr);
 end
 hlgnd(find(strcmp(nistln(ii).spec,specs)))=hnist(ii);
end
xlabel('wavelength [A]'),ylabel('intensity [arb]')
%if length(specs)>1, legend(hlgnd,specs), legend boxoff, else, title(specs), end
%axis tight

