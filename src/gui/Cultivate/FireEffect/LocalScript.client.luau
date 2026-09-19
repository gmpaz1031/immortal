local Frames = {
	"rbxassetid://111511450692604",
	"rbxassetid://114981011596094",
	"rbxassetid://81581343727786",
	"rbxassetid://136854423545530",
	"rbxassetid://88487140550182",
	"rbxassetid://130358422728297",
	"rbxassetid://110750158189645",
	"rbxassetid://110541373065075",
	"rbxassetid://124691438222167",
}

while script do
	for i = 1,#Frames do
		script.Parent.Image = Frames[i]
		task.wait(0.2)
	end
	task.wait()
end