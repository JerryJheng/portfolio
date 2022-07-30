import pandas as pd
import seaborn as sns
import matplotlib.pyplot as plt
#import data
RentData = pd.read_excel (r"C:\Users\Jheyu Jheng\Desktop\RentData.xlsx")

#add features from 'TransactionDate'
#first change object to datetime
RentData.TransactionDate = pd.to_datetime(RentData.TransactionDate)
#extract month, day_of_month features
TD_months = RentData.TransactionDate.dt.month
TD_day_of_months = RentData.TransactionDate.dt.day
#extract day name and convert it into one-hot encoding
td_to_one_hot= RentData.TransactionDate.dt.day_name()
days=pd.get_dummies(td_to_one_hot)
#convert other categorical features into one-hot encoding
District=pd.get_dummies(RentData.District)
District.columns=['Zhongli District', 'Bade District','Dayuan District','Daxi District',
                  'Pingzhen District','Xinwu District','Taoyuan District','Yangmei District',
                  'Luzhu District','Guanyin District','Longtan District','Guishan District']
UsingZone=pd.get_dummies(RentData.UsingZone)
UsingZone.columns=['Metropolis area','Specific agricultural area','Industrial area',
                   'General agricultural area', 'Rural area','Specific dedicated area',
                   'Hillside land conservation area']
Lift=pd.get_dummies(RentData.Lift)
Lift.columns=['Lift_yes','Lift_no','Lift_notsure']
Socialhousing=pd.get_dummies(RentData.Socialhousing)
Socialhousing.columns=['Socialhousing','notSocialhousing']
FurnitureProvided=pd.get_dummies(RentData.FurnitureProvided)
FurnitureProvided.columns=['FurnitureProvided','FurnitureNotProvided']
ManagingOrg=pd.get_dummies(RentData.ManagingOrg)
ManagingOrg.columns=['ManagingOrg','noManagingOrg']
#Select features
features = pd.DataFrame({
       'AgeOfBuilding':RentData.AgeOfBuilding,
       'TransactionYear':RentData.TransactionYear, 
       'BuiltYear':RentData.BuiltYear,
       'TransactionMonth':TD_months,
       'TransactionDay':TD_day_of_months,
       'BuildingTotalArea':RentData.BuildingTotalArea,
       'Floor':RentData.Floor,
       'BerthNum':RentData.BerthNum,
       'BuildingNum':RentData.BuildingNum,
       'Room':RentData.Room, 
       'Hall':RentData.Hall,
       'Toilet':RentData.Toilet, 
       'PricePerSquareMeter':RentData.PricePerSquareMeter
})
#concatenate one-hot encoding features
features=pd.concat([
        features,
        days,
        District,
        UsingZone,
        Lift,
        Socialhousing,
        FurnitureProvided,
        ManagingOrg
],axis=1)

from sklearn.model_selection import train_test_split
from sklearn.linear_model import LinearRegression, Ridge, ElasticNet
#Split data set
x= features
y= RentData['TotalPrice']
x_train, x_test, y_train, y_test=train_test_split(x,y,test_size=0.25,random_state = 439)

from sklearn import metrics
import numpy as np

# modeling
from keras.models import Sequential
from keras.layers import Dense, Dropout
import tensorflow as tf
model = Sequential([
    Dense(144, input_dim=48, activation= "relu"),
    Dense(96, activation= "relu"),
    Dense(48, activation= "relu"),
    Dense(24, activation= "relu"),
    Dense(12, activation= "relu"),
    Dense(1)
])

from keras import backend as K
# matrices help evaluating models
# caculate r^2
def coeff_determination(y_true, y_pred):
    SS_res =  K.sum(K.square( y_true-y_pred ))
    SS_tot = K.sum(K.square( y_true - K.mean(y_true) ) )
    return ( 1 - SS_res/(SS_tot + K.epsilon()) )

model.compile(loss= "mean_squared_error" , optimizer="adam", metrics=["mean_squared_error",coeff_determination])
#model.compile(loss= "mean_squared_error", optimizer=tf.keras.optimizers.SGD(0.1))
model.summary()

# fit the model
model.fit(x_train, y_train, epochs=500)

# evaluate the model
from math import sqrt
from sklearn.metrics import mean_squared_error
pred_train= model.predict(x_train)
#RMSE_train(=1173.9507269423357)
print(np.sqrt(mean_squared_error(y_train,pred_train)))
pred= model.predict(x_test)
#RMSE_test(=1710.0227918517214)
print(np.sqrt(mean_squared_error(y_test,pred))) 
#r^2_test=0.8689
r_squared_score_test=model.evaluate(x_test,y_test) #r^2(test)=0.8689
#r^_train_test(=0.9531)
r_squared_score_all=model.evaluate(x,y) 

# compare real price with predicted one
df=pd.DataFrame(pred)
df.head()
df.shape
yt=pd.DataFrame(y_test)
com=pd.concat([yt.reset_index(drop=True),df],axis=1,ignore_index=True)
com.columns=["RealPrice","PredPrice"]
com.head()

