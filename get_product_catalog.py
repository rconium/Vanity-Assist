import csv

# with open('Product_Catalog.psv', 'r') as fp:
#     reader = csv.reader(fp, delimiter='|')
#     for i, row in enumerate(reader):
#         print('Row {rownum} is {data}'.format(rownum=1+1, data=str(row)))
#         if i+1 > 9:
#             break

with open('Product_Catalog.psv', 'r') as fp:
    with open("Product_Catalog.csv", 'w') as fc:
        csv.writer(fc, delimiter=',').writerows(csv.reader(fp, delimiter='|'))