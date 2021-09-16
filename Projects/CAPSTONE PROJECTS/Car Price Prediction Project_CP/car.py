import streamlit as st
import pickle
import pandas as pd
from PIL import Image

st.title("*Car Price Prediction Project*")

img = Image.open("red_car.jpg")
st.image(img, width=500)

st.sidebar.title("Select the Feature")

model_type = st.sidebar.selectbox("Model", ('A3', 'Astra', 'Corsa', 'Insignia', 'Clio', 'Espace'))
age = st.sidebar.radio ("Age",('0','1','2','3'))
km = st.sidebar.slider("Kilometer", 0, 317000, step=1000)
hp = st.sidebar.slider("Horse Power", 40, 294, step=1)
gear = st.sidebar.radio ("Gear Type", ('Manual', 'Semi-automatic'))

my_dict = {
    "model":model_type,
    "hp":hp,
    "age":age,
    "km":km,
    "gearing_type":gear}

my_dict = pd.DataFrame([my_dict])
st.header("Your configuration is below")
st.table(my_dict)

columns=['hp', 'km', 'age', 'model_A3', 'model_Astra', 'model_Clio',
       'model_Corsa', 'model_Espace', 'model_Insignia', 'gearing_type_Manual',
       'gearing_type_Semi-automatic']

my_dict = pd.get_dummies(my_dict).reindex(columns=columns, fill_value=0)

scaler = pickle.load(open("scaler_auto", "rb"))
my_dict = scaler.transform(my_dict)

model = pickle.load(open("lasso_final_model","rb"))

st.subheader("Press 'Predict' button to submit your configuration")
if st.button("Predict"):
    prediction = model.predict(my_dict)
    st.info("The price prediction for this car is {} Euro. ".format(int(prediction)))