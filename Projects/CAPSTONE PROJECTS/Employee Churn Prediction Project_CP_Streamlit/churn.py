import streamlit as st
import pickle
import pandas as pd
from PIL import Image

st.title("*Churn Employee Prediction Project*")

img = Image.open("churn.png")
st.image(img, width=200)

st.sidebar.title("Select the Feature")

number_project = st.sidebar.selectbox("Number of Project", ('2','3','4','5','6','7'))
time_spent_company = st.sidebar.radio ("Time Spent Company", ('2','3','4','5','6','7','8','9','10'))
satisfaction_level = st.sidebar.slider("Satisfaction Level", 0.00, 1.00, step=0.05)
last_evaluation = st.sidebar.slider("Last Evaluation", 0.00, 1.00, step=0.05)
average_monthly_hours = st.sidebar.slider("Average Monthly Hours", 96, 310, step=1)

my_dict = {"number_project": number_project,
           "time_spent_company": time_spent_company,
           "satisfaction_level": satisfaction_level,
           "last_evaluation": last_evaluation,
           "average_monthly_hours": average_monthly_hours,          
          }

my_dict = pd.DataFrame([my_dict])
st.header("Your configuration is below")
st.table(my_dict)

columns=['satisfaction_level', 'last_evaluation', 'number_project',
       'average_monthly_hours', 'time_spent_company', 'work_accident',
       'promotion_last_5years', 'salary', 'departments_IT',
       'departments_RandD', 'departments_accounting', 'departments_hr',
       'departments_management', 'departments_marketing',
       'departments_product_mng', 'departments_sales', 'departments_support',
       'departments_technical']

my_dict = pd.get_dummies(my_dict).reindex(columns=columns, fill_value=0)

scaler = pickle.load(open("scaler_churn", "rb"))
my_dict = scaler.transform(my_dict)

model = pickle.load(open("final_model_rf", "rb"))

st.subheader("Press 'Predict' button to submit your configuration")
if st.button("Predict"):
    prediction = model.predict(my_dict)
    st.info("Probably, this employee is going to {} the company".format("LEAVE" if prediction ==1 else "STAY IN"))