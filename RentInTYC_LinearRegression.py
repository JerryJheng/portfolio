import numpy as np
import pandas as pd
import seaborn as sns
import matplotlib
import matplotlib.pyplot as plt
from scipy.stats import norm
from sklearn.model_selection import train_test_split
from sklearn.preprocessing import MinMaxScaler
from sklearn.linear_model import LinearRegression, Ridge, ElasticNet
import numpy as np
from sklearn import metrics
#read data
RentData = pd.read_excel ("RentData.xlsx")


#=====Correlation Matrix=====
CorrM=RentData.corr()
#plot
plt.rcParams['figure.figsize']=20,20
plt.rcParams['figure.dpi'] = 72
plt.rcParams['font.size'] = 14
plt.rcParams.update({'font.family':'Times New Roman'})
#f, ax = plt.subplots(figsize =(5, 4))
#sns.heatmap(CorrM, ax = ax, cmap ="YlGnBu", linewidths = 0.1)
sns.heatmap(CorrM, cmap ="YlGnBu", annot=True)
plt.title('Correlation Matrix for Features',fontsize=30)
plt.show()

#=====Feature Adjustment & Selection=====
RentData.TransactionDate = pd.to_datetime(RentData.TransactionDate)
RentData.BuiltDate = pd.to_datetime(RentData.BuiltDate)
# extract month, day of months features
TD_months = RentData.TransactionDate.dt.month
TD_day_of_months = RentData.TransactionDate.dt.day
# extract day name
td_to_one_hot= RentData.TransactionDate.dt.day_name()
days=pd.get_dummies(td_to_one_hot)
# convert other categorical features to one-hot encoding
District=pd.get_dummies(RentData.District)
District.columns=['Zhongli District', 'Bade District','Dayuan District','Daxi District','Pingzhen District','Xinwu District','Taoyuan District','Yangmei District','Luzhu District','Guanyin District','Longtan District','Guishan District']
UsingZone=pd.get_dummies(RentData.UsingZone)
UsingZone.columns=['Metropolis area','Specific agricultural area','Industrial area','General agricultural area', 'Rural area','Specific dedicated area','Hillside land conservation area']
Lift=pd.get_dummies(RentData.Lift)
Lift.columns=['Lift_yes','Lift_no','Lift_notsure']
Socialhousing=pd.get_dummies(RentData.Socialhousing)
Socialhousing.columns=['Socialhousing','notSocialhousing']
FurnitureProvided=pd.get_dummies(RentData.FurnitureProvided)
FurnitureProvided.columns=['FurnitureProvided','FurnitureNotProvided']
ManagingOrg=pd.get_dummies(RentData.ManagingOrg)
ManagingOrg.columns=['ManagingOrg','noManagingOrg']
# select features
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
       'Room':RentData.Room, 'Hall':RentData.Hall, 'Toilet':RentData.Toilet, 
       'PricePerSquareMeter':RentData.PricePerSquareMeter
})
#concatenate categorical features
features=pd.concat([features,days,District,UsingZone,Lift,Socialhousing,FurnitureProvided,ManagingOrg],axis=1)


#=====Modeling=====
# Split data into training set/testing set
x= features
y= RentData['TotalPrice']
x_train, x_test, y_train, y_test=train_test_split(x,y,test_size=0.25,random_state = 439) 
# Fit the regression model
#mlr=ElasticNet(alpha=0.01)
#mlr=Ridge(alpha=10,tol=0.00001,solver="svd")
mlr= LinearRegression()
mlr.fit(x_train,y_train)
# Show result
print("Intercept: ", mlr.intercept_)
print("Coefficients:")
for i in range(len(list(zip(x,mlr.coef_)))):
       print(list(zip(x,mlr.coef_))[i])
#print("Coefficients:",list(zip(x,mlr.coef_)))

# Predict on the testing set
y_pred_mlr = mlr.predict(x_test)
print("Prediction for test set: {}".format(y_pred_mlr))
mlr_diff = pd.DataFrame({'Actual value': y_test,'Predict_Value':y_pred_mlr})
print(mlr_diff)
#mlr_diff.head()
# Evaluate the Model
meanAbErr = metrics.mean_absolute_error(y_test, y_pred_mlr)
meanSqErr = metrics.mean_squared_error(y_test, y_pred_mlr)
rootMeanSqErr = np.sqrt(metrics.mean_squared_error(y_test, y_pred_mlr))
print('R squared: {:.2f}'.format(mlr.score(x,y)*100))
print('Mean Absolute Error:', meanAbErr)
print('Mean Square Error:', meanSqErr)
print('Root Mean Square Error:', rootMeanSqErr)
#mlr_diff.to_csv('mlr_diff.csv')

#show feature importance
plt.rcParams['font.size'] = 14
(pd.Series(abs(mlr.coef_), index=x.columns)
   .nsmallest(len(mlr.coef_))
   .plot(kind='barh')) 
plt.title('Feature Importance',fontsize=30)
plt.show()
