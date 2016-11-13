#!/usr/bin/env Rscript
library(RMySQL)
library(ggplot2)
library(maptools)
library(reshape2)
gpclibPermit()

# setup ----
sp = 4
spd = 60*60*24
psi = 0.000145038
now = Sys.time()
now_d = Sys.Date()

outdir = "/home/[username]/R"
mydb = dbConnect(MySQL(), user='username', password='password', dbname='test_arduino', host='192.168.1.100')
dbListTables(mydb)
dat <- dbSendQuery(mydb, "SELECT * FROM `temps` WHERE `temp_date` >= now() - INTERVAL 2 DAY;")
df = fetch(dat, n=-1)
df$stpt = as.POSIXct(strptime(df$temp_date, format="%Y-%m-%d %H:%M:%S"))
df$t=NA
df$h=NA
df$p=NA

# function to remove outliers:----
remove_outliers <- function(x, na.rm = TRUE, ...) {
  qnt <- quantile(x, probs=c(.1, .9), na.rm = na.rm, ...)
  H <- 1.5 * IQR(x, na.rm = na.rm)
  y <- x
  y[x < (qnt[1] - H)] <- NA
  y[x > (qnt[2] + H)] <- NA
  y
}

# Multiple plot function----
#
# ggplot objects can be passed in ..., or to plotlist (as a list of ggplot objects)
# - cols:   Number of columns in layout
# - layout: A matrix specifying the layout. If present, 'cols' is ignored.
#
# If the layout is something like matrix(c(1,2,3,3), nrow=2, byrow=TRUE),
# then plot 1 will go in the upper left, 2 will go in the upper right, and
# 3 will go all the way across the bottom.
#


multiplot <- function(..., plotlist=NULL, file, cols=1, layout=NULL) {
  library(grid)
  
  # Make a list from the ... arguments and plotlist
  plots <- c(list(...), plotlist)
  
  numPlots = length(plots)
  
  # If layout is NULL, then use 'cols' to determine layout
  if (is.null(layout)) {
    # Make the panel
    # ncol: Number of columns of plots
    # nrow: Number of rows needed, calculated from # of cols
    layout <- matrix(seq(1, cols * ceiling(numPlots/cols)),
                     ncol = cols, nrow = ceiling(numPlots/cols))
  }
  
  if (numPlots==1) {
    print(plots[[1]])
    
  } else {
    # Set up the page
    grid.newpage()
    pushViewport(viewport(layout = grid.layout(nrow(layout), ncol(layout))))
    
    # Make each plot, in the correct location
    for (i in 1:numPlots) {
      # Get the i,j matrix positions of the regions that contain this subplot
      matchidx <- as.data.frame(which(layout == i, arr.ind = TRUE))
      
      print(plots[[i]], vp = viewport(layout.pos.row = matchidx$row,
                                      layout.pos.col = matchidx$col))
    }
  }
}

# filter temp and humid data:----
for (i in (sp+1):(nrow(df)-sp)) {
  set = remove_outliers(df$temp_c[(i-sp):(i+sp)])
  df$t[i] = mean(set, na.rm=TRUE)*1.8+32
  set = remove_outliers(df$humid[(i-sp):(i+sp)])
  df$h[i] = mean(set, na.rm=TRUE)
  set = remove_outliers(df$pressure[(i-sp):(i+sp)])
  df$p[i] = psi*mean(set, na.rm=TRUE)
}

# subsets for plotting results----
temps = subset(df,!is.na(t), c(t,stpt))
temps$type = "Temperature (F)"
colnames(temps) = c("var","time","type")
hum = subset(df,!is.na(h),c(h,stpt))
hum$type = "Humidity (%)"
colnames(hum) = c("var","time","type")
pres = subset(df,!is.na(p),c(p,stpt))
pres$type = "Pressure (PSI)  "
colnames(pres) = c("var","time","type")
plotdata = rbind(temps,hum)

ephemeris <- function(lat, lon, date, span=1, tz="UTC") {
  
  # convert to the format we need
  lon.lat <- matrix(c(lon, lat), nrow=1)
  
  # make our sequence - using noon gets us around daylight saving time issues
  day <- as.POSIXct(date, tz=tz)
  sequence <- seq(from=day, length.out=span , by="days")
  
  # get our data
  sunrise <- sunriset(lon.lat, sequence, direction="sunrise", POSIXct.out=TRUE)
  sunset <- sunriset(lon.lat, sequence, direction="sunset", POSIXct.out=TRUE)
  solar_noon <- solarnoon(lon.lat, sequence, POSIXct.out=TRUE)
  
  # build a data frame from the vectors
  data.frame(date=as.Date(sunrise$time),
             sunrise=sunrise$time,
             sunset=sunset$time)
}

# get sunrise and sunset----
home_lat <- -122.8003859
home_lon <-   45.4849716
lon.lat <- matrix(c(home_lon, home_lat), nrow=1)
start_date = as.character(now_d-2)
span = 3 # match this to plot interval
#tz = Sys.timezone()
tz="America/Los_Angeles"

rise_set = ephemeris(home_lon, home_lat, start_date, span, tz)

if (rise_set$sunset[3]<now) {
  recx = data.frame(c(now-(2*spd),rise_set$sunrise[2],rise_set$sunset[2],rise_set$sunrise[3],rise_set$sunset[3],now))
} else if (rise_set$sunrise[3]<now) {
  recx = data.frame(c(rise_set$sunset[1],rise_set$sunrise[2],rise_set$sunset[2],rise_set$sunrise[3]))
} else {
  recx = data.frame(c(now-(2*spd),rise_set$sunrise[1],rise_set$sunset[1],rise_set$sunrise[2],rise_set$sunset[2],now))
}
colnames(recx) = "rs"
rise = subset(rise_set,sunrise>(now-1.7*spd) & sunrise<now,sunrise)
set  = subset(rise_set,sunset>(now-1.7*spd) & sunset<now,sunset)

# plot results----
p1 <- ggplot() + ylim(0,100)+ scale_y_continuous(breaks=seq(0,100,10)) + #xlim(now,now-2*spd)+
  geom_rect(data=NULL,aes(xmin=recx$rs[1],xmax=recx$rs[2],ymin=0,ymax=100), fill="azure3", alpha = 0.4)+
  geom_rect(data=NULL,aes(xmin=recx$rs[3],xmax=recx$rs[4],ymin=0,ymax=100), fill="azure3", alpha = 0.4)+
  geom_text(aes(x=rise$sunrise, y=5, hjust = 1.05), label=paste("sunrise: ",format(rise$sunrise,"%H:%M"),sep=""))+
  geom_text(aes(x=set$sunset, y=5, hjust = 1.05), label=paste("sunset: ",format(set$sunset,"%H:%M"),sep=""))

if (nrow(recx)>4) {
  p1 <- p1 + geom_rect(data=NULL,aes(xmin=recx$rs[5],xmax=recx$rs[6],ymin=0,ymax=100), fill="azure3", alpha = 0.4)
  }
p1 <- p1 + geom_line(data = plotdata, aes(x=time,y=var,color=type), size=1)+
  theme(axis.title.x=element_blank(),axis.title.y=element_blank(),legend.title=element_blank())
  
p2 <- ggplot() + ylim(14.2,15)+
  geom_rect(data=NULL,aes(xmin=recx$rs[1],xmax=recx$rs[2],ymin=14.2,ymax=15), alpha = 0.4, fill="azure3")+
  geom_rect(data=NULL,aes(xmin=recx$rs[3],xmax=recx$rs[4],ymin=14.2,ymax=15), alpha = 0.4, fill="azure3")
if (nrow(recx)>4) {
  p2 <- p2 + geom_rect(data=NULL,aes(xmin=recx$rs[5],xmax=recx$rs[6],ymin=14.2,ymax=15), alpha = 0.4, fill="azure3")}
p2 <- p2 + geom_line(data = pres, aes(x=time,y=var,color=type), size=1)+
  theme(axis.title.x=element_blank(),axis.title.y=element_blank(),legend.title=element_blank())


png(paste(outdir,"TempHumidPres.png",sep="/"),pointsize=10,width=800,height=400,res=90)
multiplot(p1, p2, cols=1)
dev.off()


