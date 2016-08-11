## 0.2.0 (2016-08-11)

####Features:

  - started changelog
  - for function `sampleRanks` removed methods with optional parameters in favor of methods with keyword parameters
	
####Bug fixes:

  - none

####Remarks:

Using optional functions like
```julia
function test(a,b=1,c=1)
	a+b+c
end


```
	together with keyword parameters:
```julia
function test(a;b=1,c=1)
	a+b+c
end


```
	results in warning messages when importing the package with `using`:
```
WARNING: Method definition test(Any) in ... overwritten at ...
```
	



